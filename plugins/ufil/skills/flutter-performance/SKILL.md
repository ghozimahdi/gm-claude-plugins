---
name: flutter-performance
description: "GM Flutter performance patterns — const class vs helper method, isolate vs compute, ListView builder, RepaintBoundary, image caching, build optimization"
disable-model-invocation: true
---

## Flutter Performance Patterns (GM Standard)

This skill teaches when to use specific patterns for performance-critical decisions in Flutter UI code.

---

## 1. Const Class vs Helper Method (CRITICAL)

### Rule: Prefer `const` widget class over helper method when the widget is reused or rebuilt frequently.

**Why it matters:**

- Helper methods are **called every rebuild** — Flutter cannot cache the returned widget tree
- `const` widgets are **instantiated once** and reused on every rebuild — Flutter skips the entire subtree
- Remi Rousselet (creator of Riverpod/Provider): _"Classes have better default behavior. The only real benefit of methods is writing a bit less code, there's no functional advantage."_

### ❌ Helper Method (avoid for reusable UI)

```dart
class MyPage extends StatelessWidget {
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
}
```

Problems:

- New `Container` allocated every rebuild
- Wastes CPU cycles
- Cannot be `const`
- Higher GC pressure on animations

### ✅ Const Widget Class (preferred)

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
- Stable identity → Flutter skips rebuild via `Element` reuse
- Better animation performance (especially in `ListView`/`GridView`)
- Lower memory churn

### When Helper Methods ARE Acceptable

Helper methods are fine when:

1. **One-shot logic** that doesn't return a widget (e.g., `String _formatPrice(...)`)
2. **Conditional widget selection** that returns different widget types
3. **Private composition inside the same widget** that uses the parent's `BuildContext` and ALL params come from `build()` — and is NOT inside an animation/list/frequently-rebuilt subtree
4. **Trivial wrappers** that themselves return a `const` widget

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

### Mandatory: Always use `const` constructor

```dart
// ❌ Missing const
class Spacer extends StatelessWidget {
  Spacer({super.key});  // bad
}

// ✅ Const constructor
class Spacer extends StatelessWidget {
  const Spacer({super.key});  // good
}
```

Adding `const` to every widget class is **non-negotiable** in this project — even StatefulWidgets must have `const` constructors.

---

## 2. Isolate vs compute() vs async/await

### Rule: Default to `async/await`. Use `compute()` for heavy CPU work. Use full `Isolate` only for long-lived background work.

### Decision Tree

```
Is the work CPU-bound (heavy computation)?
├── No (I/O, network, file read) → use async/await
└── Yes
    ├── One-shot heavy computation (>16ms) → use compute()
    └── Long-lived / streaming heavy work → use Isolate.spawn() + ports
```

### When to use `async/await` (NOT isolate)

Network calls, file I/O, database queries, `await` on Futures — these are **already non-blocking** on the UI thread. **Do not** wrap them in isolates.

```dart
// ✅ Correct — async/await is enough
Future<List<Tenant>> fetchTenants() async {
  final response = await dio.get('/tenants');
  return response.data;
}
```

### When to use `compute()` (one-shot CPU work)

Use for: JSON parsing of large payloads, image manipulation, encryption/decryption, parsing/sorting/filtering large lists, regex on huge strings.

```dart
// ✅ Heavy JSON parse — moves work off UI thread
Future<List<Tenant>> parseTenants(String rawJson) async {
  return compute(_parseTenantsSync, rawJson);
}

List<Tenant> _parseTenantsSync(String rawJson) {
  final list = jsonDecode(rawJson) as List;
  return list.map((e) => Tenant.fromJson(e)).toList();
}
```

Rules:

- The function passed to `compute()` MUST be a top-level function or `static` method
- Arguments and return values MUST be `SendPort`-compatible (primitives, lists, maps, simple objects)
- DO NOT pass `BuildContext`, `Bloc`, or any object that holds Flutter framework references

### When to use full `Isolate.spawn()` (long-lived)

Use for: continuous background processing (e.g., live image filter pipeline, real-time audio processing, long-running ML inference loop).

For this project, **prefer `compute()`** — full `Isolate` is rarely needed in CRUD apps.

### ❌ Common Mistakes

```dart
// ❌ Don't isolate I/O — it's already async
final result = await compute(_fetchFromApi, url);  // pointless

// ❌ Don't pass non-serializable objects
await compute(_doWork, context);  // crash

// ❌ Don't isolate work <16ms — the spawn cost exceeds the gain
await compute(_addTwoNumbers, [1, 2]);  // wasteful
```

---

## 3. ListView / GridView Performance

### Rule: ALWAYS use `.builder` for lists with > ~10 items. Add `const` items + cache extents.

### ❌ Renders all items eagerly

```dart
ListView(
  children: tenants.map((t) => TenantCard(tenant: t)).toList(),
)
```

### ✅ Lazy build via builder

```dart
ListView.builder(
  itemCount: tenants.length,
  itemBuilder: (context, index) => TenantCard(tenant: tenants[index]),
)
```

### Optimizations

```dart
ListView.builder(
  itemCount: tenants.length,
  itemExtent: 80.h,            // fixed height → skip layout pass
  cacheExtent: 500,            // pre-render off-screen items
  addAutomaticKeepAlives: false,
  addRepaintBoundaries: true,  // default true — keep it
  itemBuilder: (context, index) => TenantCard(
    key: ValueKey(tenants[index].id),
    tenant: tenants[index],
  ),
)
```

Rules:

- Use `itemExtent` when item height is fixed → drops layout cost
- Use `ValueKey` from a stable id (NOT index) for items that can reorder
- Avoid `shrinkWrap: true` unless inside another scrollable — it forces layout of all children

---

## 4. RepaintBoundary

### Rule: Wrap widgets that repaint independently from their parent.

Use cases:

- Animation widgets inside a static layout
- Charts / canvases / video
- Items inside a scrolling list with heavy paint operations

```dart
// ✅ Animation isolated from parent's repaint
RepaintBoundary(
  child: Lottie.asset('assets/loading.json'),
)
```

`ListView.builder` already adds `RepaintBoundary` per item by default — do NOT wrap items again.

---

## 5. Image Performance

### Rules:

- Use `cacheWidth`/`cacheHeight` to decode at display size — NOT full resolution
- Use `cached_network_image` for network images (already in many GM projects)
- Prefer `ResizeImage` over manual resize

```dart
// ❌ Decodes 4K image into memory for a 100x100 display
Image.network('https://.../photo.jpg')

// ✅ Decodes only at display size
Image.network(
  'https://.../photo.jpg',
  cacheWidth: (100 * MediaQuery.of(context).devicePixelRatio).toInt(),
  cacheHeight: (100 * MediaQuery.of(context).devicePixelRatio).toInt(),
)

// ✅ Or with cached_network_image
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,
  memCacheHeight: 200,
)
```

---

## 6. Build Method Discipline

### Rules:

- NEVER do allocation-heavy work inside `build()` (no list mapping, no parsing, no DateTime.now())
- NEVER call `setState` synchronously inside `build()`
- Move expensive computations to `initState`, `didChangeDependencies`, or memoize via `late final`
- For Bloc-driven UI, derive computed values inside the bloc state (NOT inside `build()`)

```dart
// ❌ Recomputed every rebuild
@override
Widget build(BuildContext context) {
  final filtered = tenants.where((t) => t.active).toList();  // bad
  return ListView(...);
}

// ✅ Computed once in bloc state
state.copyWith(filteredTenants: tenants.where((t) => t.active).toList())
```

---

## 7. Selector / BlocSelector — narrow rebuilds

When a widget only depends on **part** of a Bloc state, use `BlocSelector` to skip rebuilds when other state fields change.

```dart
// ❌ Whole widget rebuilds when ANY state field changes
BlocBuilder<TenantBloc, TenantState>(
  builder: (context, state) => Text(state.tenant.name),
)

// ✅ Only rebuilds when name changes
BlocSelector<TenantBloc, TenantState, String>(
  selector: (state) => state.tenant.name,
  builder: (context, name) => Text(name),
)
```

---

## 8. Animations

### Rules:

- Use `AnimatedBuilder` with a `child` parameter for static subtrees inside the animation
- Use `RepaintBoundary` around animated widgets
- Prefer implicit animations (`AnimatedContainer`, `AnimatedOpacity`) over manual `AnimationController` when possible
- For complex animations, use `Tween` + `Curves` from existing instances (don't create per build)

```dart
// ✅ child is built ONCE, not per frame
AnimatedBuilder(
  animation: _controller,
  child: const HeavyWidget(),  // built once
  builder: (context, child) => Transform.rotate(
    angle: _controller.value * 6.28,
    child: child,
  ),
)
```

---

## 9. Stream / Future Patterns

- Avoid `StreamBuilder` / `FutureBuilder` for data that flows through Bloc — let the Bloc handle the lifecycle
- Cancel `StreamSubscription` in `close()` of Bloc, `dispose()` of StatefulWidget
- Use `bufferTime` / `debounce` (rxdart) for high-frequency streams (search input, scroll events)

---

## 10. Avoid `saveLayer()` Triggers (off-screen rendering)

### Rule: Avoid widgets that silently call `Canvas.saveLayer()` — it forces the GPU to render to an off-screen buffer, then copy back. Heavy operation, FPS killer, battery drain.

`saveLayer()` is one of the most expensive Flutter operations. The GPU normally draws **directly to the screen**, but `saveLayer()` forces it to:

1. Create a separate off-screen buffer
2. Draw the UI there
3. Copy it back to the main canvas

That's **double work** per frame — multiplied by every item in a `ListView` or every frame of an animation, it crushes FPS.

### Widgets that trigger `saveLayer()` under the hood

| Widget                             | When it triggers                         | Mitigation                                                                                                                              |
| ---------------------------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `ShaderMask`                       | always                                   | use static gradient `Container` decoration if possible                                                                                  |
| `ColorFiltered` / `ColorFilter`    | always                                   | bake the filter into the asset/image instead                                                                                            |
| `BackdropFilter`                   | always                                   | use a static blurred image asset if the blur is constant                                                                                |
| `Opacity` (with child that paints) | when `opacity != 1.0 && != 0.0`          | use `AnimatedOpacity` only when needed; for images use `Image(opacity:)`; for color use `Color.withOpacity()` on `Container` decoration |
| `Chip` / `RawChip`                 | when `disabledColor` has alpha `!= 0xff` | use full-alpha disabled color OR build a custom widget                                                                                  |
| `Text` with overflow shader        | `overflow: TextOverflow.fade`            | use `TextOverflow.ellipsis` or `clip`                                                                                                   |
| `ClipPath` / `ClipOval`            | always (with anti-aliasing)              | use `BoxDecoration.shape` if possible                                                                                                   |

### ❌ Triggers `saveLayer()`

```dart
// Forces off-screen buffer for the gradient mask
ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ).createShader(bounds),
  child: Container(...),
)

// Disabled chip with translucent disabledColor → saveLayer() per frame
RawChip(
  isEnabled: false,
  disabledColor: Colors.grey.withAlpha(150),  // alpha != 0xff
  label: const Text('Disabled'),
)

// Opacity wrapping a complex subtree → entire subtree off-screen
Opacity(
  opacity: 0.5,
  child: ComplexCard(...),
)
```

### ✅ No `saveLayer()`

```dart
// Static gradient as decoration — paints directly
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
  ),
  child: ...,
)

// Use full-alpha disabled color
RawChip(
  isEnabled: false,
  disabledColor: Color(0xFFE0E0E0),  // full alpha
  label: const Text('Disabled'),
)

// Apply opacity to the color, not the widget
Container(
  color: Colors.black.withOpacity(0.5),
  child: ComplexCard(...),
)
```

### How to verify

Open **DevTools → Performance → Timeline Events** tab and filter by `saveLayer`. If you see the keyword appear thousands of times, you have a problem. Cross-reference with red **"Raster Jank"** spikes in the Frames graph.

---

## 11. ClipRRect — prefer `BoxDecoration.borderRadius`

### Rule: Use `ClipRRect` only when you MUST clip child content. For a rounded rectangle with color/gradient, use `BoxDecoration.borderRadius` on `Container` — it paints natively, no off-screen buffer.

`ClipRRect` forces off-screen rendering. `BoxDecoration` is drawn natively by the GPU in a single step.

### ❌ Expensive — clipping triggers off-screen render

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.all(16),
    color: Colors.blue,
    child: const Text('Submit'),
  ),
)
```

### ✅ Native — paints directly to screen

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Text('Submit'),
)
```

### When `ClipRRect` is actually needed

- Clipping an `Image` to rounded corners → use `ClipRRect`, OR better: `Image` inside `Container` with `BoxDecoration.image` + `borderRadius`
- Clipping a `Hero` / animated child where decoration won't work
- Rounding a child whose paint extends beyond the parent (custom painters, video, etc.)

### Decision

| Need                                   | Use                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------- |
| Rounded button / card with solid color | `Container` + `BoxDecoration`                                                 |
| Rounded gradient                       | `Container` + `BoxDecoration(gradient: ..., borderRadius: ...)`               |
| Rounded image                          | `Container` + `BoxDecoration(image: DecorationImage(...), borderRadius: ...)` |
| Clipping arbitrary child widgets       | `ClipRRect` (last resort)                                                     |

---

## 12. String Concatenation — `StringBuffer` for loops

### Rule: For string building inside a loop or any `n`-iteration accumulation, use `StringBuffer`. The `+=` operator creates a new `String` allocation on every iteration → O(n²) complexity.

In Dart, `String` is immutable. `s += x` allocates a new string of size `len(s) + len(x)` and copies the old content. In a loop, this is quadratic.

### ❌ O(n²) — allocates per iteration

```dart
String result = '';
for (final user in users) {
  result += 'Mr ${user.firstName} ${user.lastName}, ';
}
```

For 1000 users this allocates ~1000 intermediate strings, ~500K characters of throwaway memory.

### ✅ O(n) — single buffer, write in place

```dart
final buffer = StringBuffer();
for (final user in users) {
  buffer.write('Mr ${user.firstName} ${user.lastName}, ');
}
final result = buffer.toString();
```

### When `+=` is fine

- Concatenating a **small, fixed number** of strings (2–5)
- Outside a loop, single-shot expressions

```dart
// Fine — fixed concatenation
final fullName = '${user.firstName} ${user.lastName}';

// Fine — small, fixed parts
final url = baseUrl + '/api/v1' + '/users';
```

### Alternatives

- For collection-to-string with separator → use `Iterable.join()`:

```dart
// ✅ Idiomatic for joining
final result = users.map((u) => 'Mr ${u.firstName} ${u.lastName}').join(', ');
```

### Rule of thumb

| Situation                                   | Use                  |
| ------------------------------------------- | -------------------- |
| Accumulating in a `for` / `while` loop      | `StringBuffer`       |
| Joining a collection with separator         | `.map().join()`      |
| 2–5 fixed parts                             | `+` or interpolation |
| Building structured output (CSV, log lines) | `StringBuffer`       |

---

## 13. Performance Quick Checklist (Reviewer)

Before approving a UI PR, verify:

- [ ] Every `StatelessWidget` / `StatefulWidget` has `const` constructor
- [ ] No helper methods returning widgets (use class instead)
- [ ] `ListView` / `GridView` uses `.builder` for dynamic lists
- [ ] `itemExtent` set when item height is fixed
- [ ] No allocation / heavy work in `build()`
- [ ] `compute()` used for heavy CPU work, not async I/O
- [ ] `BlocSelector` used when widget depends on partial state
- [ ] `RepaintBoundary` around independent-paint widgets
- [ ] Images use `cacheWidth`/`cacheHeight` or `CachedNetworkImage` with mem cache size
- [ ] No `shrinkWrap: true` outside nested scrollables
- [ ] Stable `ValueKey` for reorderable list items
- [ ] No `ShaderMask` / `ColorFiltered` / `BackdropFilter` inside list items or animated subtrees
- [ ] No `Chip` / `RawChip` with `disabledColor` having alpha `!= 0xff`
- [ ] No `Opacity` wrapping complex children — use `Color.withOpacity()` on decoration, or `AnimatedOpacity` only when necessary
- [ ] `ClipRRect` only when truly needed — prefer `Container` + `BoxDecoration.borderRadius`
- [ ] `StringBuffer` (or `.join()`) used for string accumulation in loops — never `+=` in `for`/`while`
- [ ] No `Text` with `TextOverflow.fade` (triggers `saveLayer`) — use `ellipsis` / `clip`

---

## Anti-Pattern Reference

| Anti-pattern                                                 | Replace with                                                          |
| ------------------------------------------------------------ | --------------------------------------------------------------------- |
| `Widget _buildHeader() => Container(...)`                    | `class _Header extends StatelessWidget { const _Header(); ... }`      |
| `await compute(_fetchApi, url)`                              | `await dio.get(url)`                                                  |
| `ListView(children: list.map(...).toList())`                 | `ListView.builder(itemCount, itemBuilder)`                            |
| `Image.network(url)` for thumbnails                          | `Image.network(url, cacheWidth: ...)`                                 |
| `BlocBuilder` for one field                                  | `BlocSelector`                                                        |
| `Container()` with no decoration                             | `SizedBox()`                                                          |
| `setState` inside `build()`                                  | move to event handler / Bloc                                          |
| Computing filtered list in `build()`                         | compute in Bloc state                                                 |
| `ClipRRect(borderRadius: ..., child: Container(color: ...))` | `Container(decoration: BoxDecoration(color: ..., borderRadius: ...))` |
| `ShaderMask` for static gradient                             | `Container(decoration: BoxDecoration(gradient: ...))`                 |
| `Opacity(opacity: 0.5, child: ComplexWidget())`              | `Container(color: ...withOpacity(0.5), child: ...)`                   |
| `RawChip(disabledColor: Colors.grey.withAlpha(150))`         | `RawChip(disabledColor: Color(0xFFE0E0E0))` (full alpha)              |
| `result += '...'` inside `for`                               | `StringBuffer().write(...)` then `.toString()`                        |
| Loop building separator-joined string                        | `iterable.map(...).join(', ')`                                        |
| `Text(overflow: TextOverflow.fade)`                          | `TextOverflow.ellipsis` or `clip`                                     |

---

## References

- `${CLAUDE_PLUGIN_ROOT}/docs/PERFORMANCE.md` — Full developer-facing reference with profiling workflow and rationale
