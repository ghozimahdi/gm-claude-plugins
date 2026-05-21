# Presentation Layer Guidelines

This document describes the rules and conventions for the Presentation layer.

## Directory Structure

```
feature_{xxx}/
├── lib/
│   ├── feature_{xxx}.dart          # Main export file
│   ├── src/
│   │   ├── blocs/
│   │   │   ├── {feature}_bloc.dart
│   │   │   ├── {feature}_event.dart
│   │   │   └── {feature}_state.dart
│   │   ├── config/
│   │   │   ├── feature_{xxx}_config.dart
│   │   │   └── feature_{xxx}_route.dart
│   │   ├── di/
│   │   │   └── di.dart
│   │   ├── pages/
│   │   │   └── {page_name}_page.dart
│   │   └── widgets/
│   │       └── {widget_name}.dart
```

## Page Rules — UseCase Access (NON-NEGOTIABLE)

**Pages MUST NOT call UseCases directly.** Every async action — even one-shot operations like `logout`, `refresh`, `delete`, `markAsRead`, `togglePin` — goes through a Bloc. There is **no** "too simple to need a Bloc" exception.

The page only ever does:
- `context.read<TBloc>().add(event)` to dispatch an event
- `BlocBuilder` / `BlocConsumer` / `BlocSelector` / `BlocListener` to read state

A page that **imports a UseCase** or calls **`getIt<XUseCase>()`** is ALWAYS wrong — even if it works, even if the test passes. The fix is:
1. Add a sub-state class for the action (`{Action}State` with `idle`/`loading`/`done`/`error` variants)
2. Add an event to the bloc (`{Feature}Event.{action}(...)`)
3. Inject the UseCase into the bloc constructor (`@injectable` Bloc + `@lazySingleton` UseCase)
4. Page dispatches the event via `context.read<TBloc>().add(...)` and listens to the sub-state

This rule has zero exceptions. Anything an `await` touches inside a page is a smell.

### Forbidden patterns (auto-flag in review)

```dart
// ❌ WRONG — page imports UseCase
import 'package:domain_auth/src/use_cases/logout_use_case.dart';

// ❌ WRONG — page resolves UseCase from getIt
final logout = getIt<LogoutUseCase>();

// ❌ WRONG — page awaits a UseCase / repository directly
ElevatedButton(
  onPressed: () async {
    await getIt<LogoutUseCase>().call();
    context.router.replace(const AuthRoute());
  },
  child: const Text('Logout'),
)

// ❌ WRONG — page reaches into a service layer (Dio, HTTP client, repo) directly
final response = await getIt<Dio>().post('/auth/logout');
```

### Correct pattern

```dart
// ✅ CORRECT — page only dispatches and reads through Bloc
ElevatedButton(
  onPressed: () => context.read<ProfileBloc>().add(const ProfileEvent.logout()),
  child: BlocSelector<ProfileBloc, ProfileState, bool>(
    selector: (state) => state.logoutState is LogoutLoadingState,
    builder: (context, isLoading) {
      return Text(isLoading ? 'Logging out…' : 'Logout');
    },
  ),
)

// Navigation lives in BlocListener, NOT in the onPressed
BlocListener<ProfileBloc, ProfileState>(
  listenWhen: (prev, curr) => prev.logoutState != curr.logoutState,
  listener: (context, state) {
    switch (state.logoutState) {
      case LogoutDoneState():
        context.router.replaceAll([const AuthRoute()]);
      case LogoutErrorState(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.toString())),
        );
      case _LogoutIdleState() || LogoutLoadingState():
        break;
    }
  },
  child: ...,
)
```

## Page Rules

### Route Provider Pattern

1. Check if `RouteProvider` is available in `feature_common/lib/src/route/{page_name}_route_provider.dart`
2. If not available, create the abstract class in feature_common
3. Implement the route provider in the page file

**Abstract Route Provider (in feature_common):**
```dart
// feature_common/lib/src/route/login_route_provider.dart
import 'package:auto_route/auto_route.dart';

abstract class LoginRouteProvider {
  PageRouteInfo route();
}
```

**Implementation (in feature page):**
```dart
import 'package:auto_route/auto_route.dart';
import 'package:feature_auth/src/config/feature_auth_route.gr.dart';
import 'package:feature_common/feature_common.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider {
  @override
  PageRouteInfo route() {
    return LoginRoute();
  }
}

@RoutePage()
class LoginPage extends StatelessWidget {
  // ...
}
```

### StatelessWidget Page (No Controllers)

Use when the page doesn't need controllers that require disposal.

```dart
@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider {
  @override
  PageRouteInfo route() {
    return LoginRoute();
  }
}

@RoutePage()
class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LoginBloc>()
        ..add(const LoginEvent.init()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: ...,
            ),
          );
        },
      ),
    );
  }
}
```

### StatefulWidget Page (With Controllers)

Use when the page needs controllers like `TabController`, `TextEditingController`, `ScrollController`.

```dart
@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider {
  @override
  PageRouteInfo route() {
    return LoginRoute();
  }
}

@RoutePage()
class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _bloc = getIt<LoginBloc>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _bloc
        ..add(const LoginEvent.init()),
      child: Scaffold(
        body: SafeArea(
          child: ...,
        ),
      ),
    );
  }
}
```

### Important Page Rules

1. **Pages MUST NOT call UseCases directly** — see "Page Rules — UseCase Access" above. Every async action goes through a Bloc, no exceptions.
2. **Do NOT create separate content classes** - Keep all content in the same page class
3. **Do NOT store state variables in Page** - Store them in BLoC state instead
4. **Extract deep nested layouts into functions** - Use `_buildXxx(BuildContext context)` methods
5. **Always import the generated route file** - `import 'package:feature_xxx/src/config/feature_xxx_route.gr.dart';`
6. **A page that imports a UseCase or `getIt<XUseCase>()` is ALWAYS wrong** — even for "trivial" actions (logout, refresh, delete). Fix by adding a sub-state + event + bloc handler.

## BlocSelector vs BlocBuilder

### Use BlocSelector for Single Field

```dart
BlocSelector<HomeBloc, HomeState, String>(
  selector: (state) => state.title,
  builder: (context, title) => Text(
    title,
    style: textTheme.bodyLarge,
  ),
),
```

### Use BlocBuilder for Multiple Fields

```dart
BlocBuilder<HomeBloc, HomeState>(
  buildWhen: (previous, current) {
    return previous.title != current.title ||
      previous.subtitle != current.subtitle;
  },
  builder: (context, state) => Text(
    '${state.title} - ${state.subtitle}',
    style: textTheme.bodyLarge,
  ),
),
```

## Widget Extraction

### List Items in Separate Widget Files

Create separate widget files for list items in the `widget/` folder:

**Page file:**
```dart
BlocSelector<HomeBloc, HomeState, List<ExpenseModel>>(
  selector: (state) => state.transactionState.transactionList,
  builder: (context, transactionList) {
    return ListView.builder(
      itemCount: transactionList.length,
      itemBuilder: (context, index) {
        return SummaryItem(item: transactionList[index]);
      },
    );
  },
),
```

**Widget file (`widget/summary_item.dart`):**
```dart
import 'package:domain_auth/domain_auth.dart';

class SummaryItem extends StatelessWidget {
  final BoosterPurchaseModel item;

  const SummaryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon),
        Column(
          children: [
            Text(item.label),
            Text(item.value),
          ],
        ),
      ],
    );
  }
}
```

## Configuration

### Feature Config (`feature_{xxx}_config.dart`)

```dart
import 'package:feature_auth/src/di/di.dart';
import 'package:library_common/library_common.dart';

class FeatureAuthConfig extends AppConfig {
  FeatureAuthConfig._();

  factory FeatureAuthConfig.getInstance() => _instance;

  static final FeatureAuthConfig _instance = FeatureAuthConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
```

### Route Config (`feature_{xxx}_route.dart`)

```dart
import 'package:auto_route/auto_route.dart';

@AutoRouterConfig()
abstract class FeatureAuthRoute {}
```

### DI Setup (`di.dart`)

```dart
import 'package:feature_auth/src/di/di.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureInjection({required String env}) async =>
    getIt.init(environment: env);
```

## Export Rules

Every new file MUST be exported in `feature_{xxx}.dart`:

```dart
// feature_booster.dart
export 'src/config/feature_booster_config.dart';
export 'src/config/feature_booster_route.dart';
export 'src/config/feature_booster_route.gr.dart';
```

Export order:
1. Config exports
2. Route exports
3. Route generated exports

## Import Rules

- All imports MUST use full package paths
- Never use relative imports

```dart
// Correct
import 'package:domain_agent/domain_agent.dart';
import 'package:feature_auth/src/config/feature_auth_route.gr.dart';

// Incorrect
import '../model/...';
import './widget/...';
```

## Colors — flutter_gen `AppColors` (NON-NEGOTIABLE)

Every color used in the presentation layer MUST come from the generated `AppColors` class (produced by `flutter_gen` from `colors.xml`). This applies to BOTH project types.

**Source of truth:**

| Project type  | `colors.xml` location                                              | Generated file                                                       | Regen command                                              |
| ------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| Modular       | `packages/presentation/feature_common/assets/colors/colors.xml`    | `packages/presentation/feature_common/lib/gen/colors.gen.dart`       | `melos run generate:assets`                                    |
| Single-module | `assets/colors/colors.xml`                                         | `lib/gen/colors.gen.dart`                                            | `fvm dart run build_runner build --delete-conflicting-outputs` |

### ❌ Forbidden

```dart
Container(color: Color(0xFFEF5350))                       // raw hex literal
Container(color: Colors.red)                              // material Colors.*
Container(color: Colors.grey.shade400)                    // .shadeXxx
Container(color: Color(int.parse('0xFFEF5350')))          // runtime-parsed hex
ThemeData(primaryColor: const Color(0xFF1976D2))          // hex in theme builder
```

### ✅ Required

```dart
import 'package:feature_common/gen/colors.gen.dart';     // modular
// import 'package:<app_name>/gen/colors.gen.dart';      // single-module

Container(color: AppColors.danger)
Container(color: AppColors.brandPrimary)
ThemeData(primaryColor: AppColors.brandPrimary)
```

### Adding a new color

Never inline a hex literal "temporarily". The required sequence:

1. Add the entry to `colors.xml`:
   ```xml
   <color name="brandAccent">#FF8A65</color>
   ```
2. Run the regen command for your project type (see table above).
3. Use the generated reference: `AppColors.brandAccent`.

### Exception

The generated `colors.gen.dart` file is the ONLY file allowed to contain raw `Color(0x..)` literals. It must never be hand-edited — always regenerate from `colors.xml`.
