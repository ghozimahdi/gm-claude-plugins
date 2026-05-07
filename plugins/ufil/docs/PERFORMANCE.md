# Flutter Performance Guidelines

This document describes performance best practices for Flutter UI and Dart code in this project. It is intended as a reading reference for developers — the agent-facing rules live in [`skills/flutter-performance/SKILL.md`](../skills/flutter-performance/SKILL.md).

The patterns here are the result of profiling real apps with Flutter DevTools. Every "rule" below has a measurable impact on FPS, jank, memory churn, or battery drain.

---

## Table of Contents

1. [Const Class vs Helper Method](#1-const-class-vs-helper-method)
2. [Isolate vs `compute()` vs `async/await`](#2-isolate-vs-compute-vs-asyncawait)
3. [ListView / GridView Optimization](#3-listview--gridview-optimization)
4. [RepaintBoundary](#4-repaintboundary)
5. [Image Performance](#5-image-performance)
6. [Build Method Discipline](#6-build-method-discipline)
7. [BlocSelector — Narrow Rebuilds](#7-blocselector--narrow-rebuilds)
8. [Animations](#8-animations)
9. [Stream / Future Patterns](#9-stream--future-patterns)
10. [Avoiding `saveLayer()`](#10-avoiding-savelayer)
11. [ClipRRect vs BoxDecoration.borderRadius](#11-cliprrect-vs-boxdecorationborderradius)
12. [String Concatenation — `+=` vs `StringBuffer`](#12-string-concatenation----vs-stringbuffer)
13. [Performance Profiling Workflow](#13-performance-profiling-workflow)
14. [Performance Review Checklist](#14-performance-review-checklist)

---

## 1. Const Class vs Helper Method

### The Problem

When cleaning up UI code, most developers reach for helper methods:

```dart
Widget _buildPixelContainer() {
  return Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: Colors.red.shade400,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}
```

It looks clean. But **Flutter cannot cache the returned widget tree**. Every rebuild, the helper method is called, allocates a new `Container`, a new `BoxDecoration`, a new `BorderRadius`, etc.

Inside a `ListView` or animation, this multiplies — thousands of throwaway allocations per second. CPU spends time on GC, frames drop.

> Remi Rousselet (creator of Riverpod & Provider): _"Classes have better default behavior. The only real benefit of methods is writing a bit less code, there's no functional advantage."_

### The Solution: `const` Widget Class

```dart
class PixelBox extends StatelessWidget {
  const PixelBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Color(0xFFEF5350),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// Usage — Flutter caches this single instance
const PixelBox()
```

Benefits:

- Allocated **once**, reused on every rebuild
- Stable element identity → Flutter skips rebuild via `Element` reuse
- Better animation performance (especially in scroll lists)
- Lower memory churn → fewer GC pauses

### When Helper Methods Are Acceptable

Helper methods aren't always wrong. They're fine for:

1. Returning a non-widget value (`String _formatPrice(...)`, `double _computeWidth(...)`)
2. Conditional widget selection inside a single `build()`:
   ```dart
   Widget _statusIcon() {
     if (status == Status.loading) return const _LoadingDot();
     if (status == Status.error) return const _ErrorDot();
     return const _SuccessDot();
   }
   ```
3. Trivial wrappers that already return a `const` widget
4. One-shot composition that uses local `build()` parameters AND is NOT inside a list/animation

### Decision Matrix

| Situation                                                | Use              |
| -------------------------------------------------------- | ---------------- |
| Widget reused in multiple places                         | `const` class    |
| Inside `ListView.builder` itemBuilder                    | `const` class    |
| Inside `AnimatedBuilder` / `ValueListenableBuilder`      | `const` class    |
| Widget rebuilt frequently (animations, streams)          | `const` class    |
| Static UI element (icon, divider, spacer)                | `const` class    |
| One-time conditional `if/else` inside a single `build()` | helper method OK |
| Returns non-widget (String, double, etc.)                | helper method OK |

### Mandatory: Always Use `const` Constructor

In this project, **every** `StatelessWidget` and `StatefulWidget` MUST have a `const` constructor. No exceptions.

```dart
// WRONG
class Spacer extends StatelessWidget {
  Spacer({super.key});
}

// CORRECT
class Spacer extends StatelessWidget {
  const Spacer({super.key});
}
```

---

## 2. Isolate vs `compute()` vs `async/await`

### Default: `async/await`

Network calls, file I/O, database queries, and anything that uses `await` is **already non-blocking** on the UI thread. Do not wrap them in isolates.

```dart
// CORRECT — async/await is enough
Future<List<Tenant>> fetchTenants() async {
  final response = await dio.get('/tenants');
  return response.data;
}
```

### Use `compute()` for One-Shot CPU Work

Use `compute()` when you have heavy CPU work that takes more than ~16ms (one frame):

- Parsing a large JSON payload (>10K objects)
- Image manipulation (resize, blur, filters)
- Encryption / decryption
- Sorting / filtering very large lists
- Regex over large strings

```dart
Future<List<Tenant>> parseTenants(String rawJson) async {
  return compute(_parseTenantsSync, rawJson);
}

List<Tenant> _parseTenantsSync(String rawJson) {
  final list = jsonDecode(rawJson) as List;
  return list.map((e) => Tenant.fromJson(e)).toList();
}
```

**Rules for `compute()`:**

- The function MUST be a top-level function or a `static` method
- Arguments and return values MUST be `SendPort`-compatible (primitives, lists, maps, simple objects via `fromJson`/`toJson`)
- DO NOT pass `BuildContext`, `Bloc`, or anything holding Flutter framework references
- Spawning an isolate has overhead (~5–20ms) — only use it when the work itself is heavier

### Use Full `Isolate.spawn()` for Long-Lived Background Work

Use a full isolate (with bidirectional `SendPort`/`ReceivePort`) only for:

- Continuous background processing (e.g., audio pipeline, ML inference loop)
- Long-running tasks that send progress updates
- Background work that survives multiple events

For CRUD-style apps, this is rarely needed. Prefer `compute()`.

### Common Mistakes

```dart
// WRONG — I/O is already async
final result = await compute(_fetchFromApi, url);

// WRONG — non-serializable object crashes the isolate
await compute(_doWork, context);

// WRONG — work too small, isolate spawn cost > the gain
await compute(_addTwoNumbers, [1, 2]);
```

---

## 3. ListView / GridView Optimization

### Always Use `.builder` for Dynamic Lists

```dart
// WRONG — renders all items eagerly, even off-screen
ListView(
  children: tenants.map((t) => TenantCard(tenant: t)).toList(),
)

// CORRECT — lazy build, only visible items rendered
ListView.builder(
  itemCount: tenants.length,
  itemBuilder: (context, index) => TenantCard(tenant: tenants[index]),
)
```

### Optimization Flags

```dart
ListView.builder(
  itemCount: tenants.length,
  itemExtent: 80.h,            // fixed height → skip layout pass
  cacheExtent: 500,            // pre-render off-screen items
  addAutomaticKeepAlives: false,
  itemBuilder: (context, index) => TenantCard(
    key: ValueKey(tenants[index].id),  // stable key for reorderable items
    tenant: tenants[index],
  ),
)
```

**Key points:**

- Use `itemExtent` when item height is fixed → drops the layout cost per item
- Use `ValueKey` from a stable id (NOT index) for items that can reorder, insert, or delete
- Avoid `shrinkWrap: true` unless inside another scrollable — it forces layout of all children, defeating lazy rendering
- `addRepaintBoundaries: true` is the default and should stay

---

## 4. RepaintBoundary

`RepaintBoundary` isolates a widget's paint operations from its parent. When the parent repaints, the boundary's cached layer is reused.

Use it for:

- Animated widgets inside a static layout
- Charts, canvases, video players
- Items inside a scrolling list with heavy paint operations

```dart
RepaintBoundary(
  child: Lottie.asset('assets/loading.json'),
)
```

**Don't double-wrap:** `ListView.builder` already adds `RepaintBoundary` around each item by default. Wrapping items again has no benefit and adds overhead.

---

## 5. Image Performance

### Decode at Display Size, Not Source Size

A 4000×3000 image displayed at 100×100 still allocates 4000×3000×4 bytes (~48MB) of bitmap memory by default. Multiply by 50 list items → 2.4GB.

```dart
// WRONG — full-resolution decode
Image.network('https://.../photo.jpg')

// CORRECT — decoded at display size
Image.network(
  'https://.../photo.jpg',
  cacheWidth: (100 * MediaQuery.of(context).devicePixelRatio).toInt(),
  cacheHeight: (100 * MediaQuery.of(context).devicePixelRatio).toInt(),
)
```

### `cached_network_image` for Network Images

Use `cached_network_image` with `memCacheWidth`/`memCacheHeight` for disk + memory caching plus on-device resize:

```dart
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,
  memCacheHeight: 200,
  placeholder: (_, __) => const ImagePlaceholder(),
  errorWidget: (_, __, ___) => const ImageError(),
)
```

---

## 6. Build Method Discipline

The `build()` method runs on every rebuild. Anything expensive here multiplies frame cost.

### Rules

- NO list mapping, parsing, or filtering inside `build()`
- NO `DateTime.now()` or other side-effectful computations
- NO `setState` synchronously inside `build()` (causes infinite rebuild loop)
- Move expensive computations to `initState()`, `didChangeDependencies()`, or memoize via `late final`
- For Bloc-driven UI, derive computed values inside the bloc state, NOT inside `build()`

```dart
// WRONG — recomputed every rebuild
@override
Widget build(BuildContext context) {
  final filtered = tenants.where((t) => t.active).toList();
  return ListView(...);
}

// CORRECT — computed once in bloc state
state.copyWith(filteredTenants: tenants.where((t) => t.active).toList())
```

---

## 7. BlocSelector — Narrow Rebuilds

When a widget only depends on **part** of a Bloc state, use `BlocSelector`. It only rebuilds when the selected value changes.

```dart
// WRONG — rebuilds on ANY state change, even unrelated fields
BlocBuilder<TenantBloc, TenantState>(
  builder: (context, state) => Text(state.tenant.name),
)

// CORRECT — only rebuilds when name changes
BlocSelector<TenantBloc, TenantState, String>(
  selector: (state) => state.tenant.name,
  builder: (context, name) => Text(name),
)
```

For nested objects, ensure the selector returns a stable reference (use Freezed `==` properly).

---

## 8. Animations

### Use `AnimatedBuilder.child` for Static Subtrees

The `child` parameter is built **once**. The builder is called per frame but the child reference stays stable.

```dart
AnimatedBuilder(
  animation: _controller,
  child: const HeavyWidget(),  // built once
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * 6.28,
    child: child,  // reused across frames
  ),
)
```

### Other Animation Rules

- Wrap animated widgets in `RepaintBoundary` to isolate their paint
- Prefer implicit animations (`AnimatedContainer`, `AnimatedOpacity`) over manual `AnimationController` when possible
- Reuse `Tween` and `Curves` instances — don't create them per build

---

## 9. Stream / Future Patterns

- Avoid `StreamBuilder` / `FutureBuilder` for data that flows through Bloc — let the Bloc handle the lifecycle
- Cancel `StreamSubscription` in `close()` of Bloc, `dispose()` of StatefulWidget
- For high-frequency streams (search input, scroll events), use `bufferTime` / `debounce` (rxdart) to reduce rebuild rate

---

## 10. Avoiding `saveLayer()`

`Canvas.saveLayer()` is one of the most expensive Flutter operations. The GPU normally draws **directly to the screen**, but `saveLayer()` forces it to:

1. Create a separate off-screen buffer
2. Draw the UI there
3. Copy it back to the main canvas

That's **double work** per frame — and many widgets trigger it implicitly without warning.

### Widgets That Trigger `saveLayer()`

| Widget                          | When it triggers                         | Mitigation                                                                                                                 |
| ------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `ShaderMask`                    | always                                   | use static gradient via `Container` decoration if possible                                                                 |
| `ColorFiltered` / `ColorFilter` | always                                   | bake the filter into the asset/image instead                                                                               |
| `BackdropFilter`                | always                                   | use a static blurred image asset if the blur is constant                                                                   |
| `Opacity` (with painted child)  | when `opacity != 1.0 && != 0.0`          | use `Image(opacity:)` for images, `Color.withOpacity()` on `BoxDecoration` for color, `AnimatedOpacity` only when animated |
| `Chip` / `RawChip`              | when `disabledColor` has alpha `!= 0xff` | use full-alpha disabled color or build a custom widget                                                                     |
| `Text` with overflow shader     | `overflow: TextOverflow.fade`            | use `TextOverflow.ellipsis` or `clip`                                                                                      |
| `ClipPath` / `ClipOval`         | always (with anti-aliasing)              | use `BoxDecoration.shape: BoxShape.circle` for circles                                                                     |

### Concrete Examples

```dart
// WRONG — ShaderMask forces off-screen render every frame
ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ).createShader(bounds),
  child: Container(...),
)

// CORRECT — gradient as decoration, painted directly
Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
  ),
  child: ...,
)
```

```dart
// WRONG — translucent disabledColor triggers saveLayer per frame
RawChip(
  isEnabled: false,
  disabledColor: Colors.grey.withAlpha(150),
  label: const Text('Disabled'),
)

// CORRECT — full-alpha color
RawChip(
  isEnabled: false,
  disabledColor: const Color(0xFFE0E0E0),
  label: const Text('Disabled'),
)
```

```dart
// WRONG — Opacity wrapping complex child → entire subtree off-screen
Opacity(
  opacity: 0.5,
  child: ComplexCard(...),
)

// CORRECT — apply opacity to the color, not the widget
Container(
  color: Colors.black.withOpacity(0.5),
  child: ComplexCard(...),
)
```

### How to Detect

1. Open **DevTools → Performance**
2. Scroll/animate the suspect screen
3. In the Frames graph, look for red **"Raster Jank"** spikes
4. Click the **Timeline Events** tab
5. Filter by `saveLayer`
6. If you see thousands of `Canvas::saveLayer` events per second, you have a problem

---

## 11. ClipRRect vs BoxDecoration.borderRadius

`ClipRRect` forces off-screen rendering. `BoxDecoration` is drawn natively by the GPU in a single pass.

### The Problem

```dart
// WRONG — clipping triggers off-screen render
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blue,
    child: const Text('Submit'),
  ),
)
```

### The Solution

```dart
// CORRECT — paints directly to screen, zero wasted GPU work
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Text('Submit'),
)
```

### When `ClipRRect` Is Actually Needed

`ClipRRect` is the right tool when you need to clip child content whose paint actually extends beyond bounds:

- Clipping an `Image` to rounded corners — though `Container` + `BoxDecoration.image` + `borderRadius` is usually better
- Clipping a `Hero` or animated child where decoration won't work
- Rounding a `CustomPaint`, video player, or any widget that paints outside its bounds

### Decision

| Need                                   | Use                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------- |
| Rounded button / card with solid color | `Container` + `BoxDecoration`                                                 |
| Rounded gradient                       | `Container` + `BoxDecoration(gradient: ..., borderRadius: ...)`               |
| Rounded image                          | `Container` + `BoxDecoration(image: DecorationImage(...), borderRadius: ...)` |
| Clipping arbitrary child widgets       | `ClipRRect` (last resort)                                                     |

---

## 12. String Concatenation — `+=` vs `StringBuffer`

In Dart, `String` is immutable. The expression `s += x` allocates a new string of size `len(s) + len(x)` and copies the entire content.

Inside a loop, this is **O(n²)**: for `n` users, you allocate `1 + 2 + 3 + ... + n` characters of throwaway memory.

### The Problem

```dart
// WRONG — O(n²), allocates a new string per iteration
String result = '';
for (final user in users) {
  result += 'Mr ${user.firstName} ${user.lastName}, ';
}
```

For 1000 users, this allocates ~1000 intermediate strings totaling ~500K characters of garbage. The GC will pause your UI thread to clean it up.

### The Solution: `StringBuffer`

```dart
// CORRECT — O(n), single buffer written in place
final buffer = StringBuffer();
for (final user in users) {
  buffer.write('Mr ${user.firstName} ${user.lastName}, ');
}
final result = buffer.toString();
```

### The Idiomatic Solution: `.join()`

For collections joined by a separator, use `Iterable.join()`:

```dart
// IDIOMATIC — readable + O(n) under the hood
final result = users
    .map((u) => 'Mr ${u.firstName} ${u.lastName}')
    .join(', ');
```

### When `+=` Is Fine

- Concatenating a **small, fixed number** of strings (2–5)
- Outside a loop, single-shot expressions

```dart
final fullName = '${user.firstName} ${user.lastName}';
final url = baseUrl + '/api/v1' + '/users';
```

### Rule of Thumb

| Situation                                   | Use                  |
| ------------------------------------------- | -------------------- |
| Accumulating in a `for` / `while` loop      | `StringBuffer`       |
| Joining a collection with separator         | `.map().join()`      |
| 2–5 fixed parts                             | `+` or interpolation |
| Building structured output (CSV, log lines) | `StringBuffer`       |

---

## 13. Performance Profiling Workflow

Before optimizing, **profile**. Most performance issues aren't where you think they are.

### Setup

1. Run app in **profile mode** (NOT debug):

   ```bash
   fvm flutter run --profile
   ```

   Debug mode is misleading — assertions, JIT, and debug overlays make everything slower than reality.

2. Open DevTools (link printed in terminal, or via IDE)

### Workflow

1. **Performance tab** → click **Record**
2. Reproduce the laggy interaction (scroll, animate, navigate)
3. Stop recording
4. Look at the **Frames** graph at the top:
   - Blue bars = UI thread work
   - Red bars = Raster thread work (GPU)
   - Yellow/red triangles = jank frames (>16ms or >8ms for 120Hz)
5. Click a janky frame → see what dominated it

### What to Look For

| Symptom                            | Likely Cause                                                  |
| ---------------------------------- | ------------------------------------------------------------- |
| Tall blue bars (UI thread)         | Heavy `build()`, expensive Bloc transitions, sync work        |
| Tall red bars (Raster thread)      | `saveLayer()` storms, complex shaders, large image decodes    |
| Steady frame drops while scrolling | Non-`.builder` ListView, missing `itemExtent`, helper methods |
| Spikes during animation            | Animated widget without `RepaintBoundary` or `child:` reuse   |
| GC pauses (small frequent drops)   | Allocations in `build()`, helper methods, `+=` in loops       |

### Useful DevTools Filters

- **Timeline Events tab** → search `saveLayer` to find off-screen render triggers
- **Rebuild Stats tab** → find widgets that rebuild more than they should
- **Memory tab** → check for leaks and allocation spikes

### Verifying a Fix

After applying a fix:

1. Re-run the same interaction in profile mode
2. Compare the Frames graph — fewer/shorter red bars
3. Check FPS counter — should be ~120 FPS on modern devices, ~60 FPS minimum
4. Confirm no new jank introduced elsewhere

---

## 14. Performance Review Checklist

Use this checklist before opening a UI-related PR.

**Widget Construction**

- [ ] Every `StatelessWidget` / `StatefulWidget` has a `const` constructor
- [ ] No helper methods returning widgets — extracted to `const` widget classes
- [ ] No `Container()` with no decoration — replaced with `SizedBox()`

**Lists**

- [ ] `ListView` / `GridView` uses `.builder` for dynamic content
- [ ] `itemExtent` set when item height is fixed
- [ ] Stable `ValueKey` (from id, not index) for reorderable items
- [ ] No `shrinkWrap: true` outside nested scrollables
- [ ] No extra `RepaintBoundary` around `ListView.builder` items

**Build Method**

- [ ] No allocation, parsing, or filtering inside `build()`
- [ ] Computed values derived in Bloc state, not in `build()`
- [ ] `BlocSelector` used when widget depends on partial state

**CPU & Threading**

- [ ] `compute()` used for heavy CPU work (>16ms)
- [ ] `compute()` NOT wrapping `async/await` I/O calls
- [ ] `StringBuffer` (or `.join()`) used for string accumulation in loops

**Painting & Rendering**

- [ ] No `ShaderMask` / `ColorFiltered` / `BackdropFilter` inside list items or animated subtrees
- [ ] No `Opacity` wrapping complex children — use `Color.withOpacity()` or `AnimatedOpacity`
- [ ] No `Chip` / `RawChip` with translucent `disabledColor` (alpha != 0xff)
- [ ] No `Text` with `TextOverflow.fade`
- [ ] `ClipRRect` only when truly needed — prefer `Container` + `BoxDecoration.borderRadius`

**Images**

- [ ] `Image.network` uses `cacheWidth` / `cacheHeight` for thumbnails
- [ ] `CachedNetworkImage` uses `memCacheWidth` / `memCacheHeight`

**Animations**

- [ ] `AnimatedBuilder` uses `child:` parameter for static subtrees
- [ ] Animated widgets wrapped in `RepaintBoundary`
- [ ] `Tween` / `Curves` instances reused, not recreated per build

**Streams**

- [ ] `StreamSubscription` cancelled in `close()` / `dispose()`
- [ ] High-frequency streams debounced / buffered

---

## References

- [skills/flutter-performance/SKILL.md](../skills/flutter-performance/SKILL.md) — Agent-facing rules and decision matrix
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices) — Official Flutter docs
- [Flutter DevTools — Performance View](https://docs.flutter.dev/tools/devtools/performance) — Profiling guide
- [Shader compilation jank](https://docs.flutter.dev/perf/shader) — Shader pre-compilation guide
