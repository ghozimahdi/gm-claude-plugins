---
name: auto-route
description: "GM Auto Route patterns — modular (RouteProvider + per-feature router) vs non-modular (single AppRouter)"
---

Resolve `UFIL_ROOT` to the plugin root containing this skill. Claude Code may
provide `CLAUDE_PLUGIN_ROOT`; Codex can resolve it from the installed skill
path.

## Auto Route Patterns (GM Standard)

### Non-Modular — Single AppRouter

```dart
// lib/app_router.dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: SplashRoute.page, initial: true),
      AutoRoute(page: LoginRoute.page),
      AutoRoute(page: RegisterRoute.page),
      AutoRoute(
        page: MainRoute.page,
        children: [
          AutoRoute(page: DashboardRoute.page),
          AutoRoute(page: PropertyListRoute.page),
          AutoRoute(page: TenantListRoute.page),
          AutoRoute(page: SettingsRoute.page),
        ],
      ),
      AutoRoute(page: PropertyDetailRoute.page),
      AutoRoute(page: AddPropertyRoute.page),
    ];
  }
}
```

Every page uses `@RoutePage()`:
```dart
@RoutePage()
class PropertyDetailPage extends StatelessWidget {
  const PropertyDetailPage({
    super.key,
    required this.propertyId,
  });

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PropertyDetailBloc>()
        ..add(PropertyDetailEvent.started(propertyId: propertyId)),
      child: const _PropertyDetailView(),
    );
  }
}
```

Navigation:
```dart
// Push
context.router.push(PropertyDetailRoute(propertyId: '123'));

// Replace
context.router.replace(const MainRoute());

// Pop
context.router.maybePop();

// Pop with result
context.router.maybePop(true);
```

Auth guard:
```dart
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);
  final AuthRepository _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isLoggedIn()) {
      resolver.next(true);
    } else {
      resolver.redirect(const LoginRoute());
    }
  }
}
```

Register router in DI:
```dart
// lib/injector.dart
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
  getIt.init();
}
```

### Modular — RouteProvider + Per-Feature Router

Each feature defines its own router and registers routes via DI:

**1. Feature router (per-feature package):**
```dart
// packages/presentation/feature_auth/lib/src/config/feature_auth_route.dart
@AutoRouterConfig()
class FeatureAuthRoute extends RootStackRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: LoginRoute.page),
    ];
  }
}
```

**2. Route provider abstraction (feature_common):**
```dart
// packages/presentation/feature_common/lib/src/routes/login_route_provider.dart
abstract class LoginRouteProvider {
  PageRouteInfo route();
}

// packages/presentation/feature_common/lib/src/routes/home_route_provider.dart
abstract class HomeRouteProvider {
  PageRouteInfo route();
}
```

**3. Route provider implementation (feature package):**
```dart
// packages/presentation/feature_auth/lib/src/pages/login_page.dart
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Login')),
    );
  }
}

// DI registration
@Injectable(as: LoginRouteProvider)
class LoginRouteProviderImpl implements LoginRouteProvider {
  @override
  PageRouteInfo route() {
    return const LoginRoute();
  }
}
```

**4. App router aggregates all routes:**
```dart
// app/lib/app_router.dart
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: HomeRoute.page, initial: true),
      AutoRoute(page: LoginRoute.page),
    ];
  }
}
```

**5. Navigate using route provider (decoupled):**
```dart
// From any feature, navigate without importing another feature directly
final loginProvider = getIt<LoginRouteProvider>();
context.router.push(loginProvider.route());
```

### Key Rules
- Every page MUST have `@RoutePage()` annotation
- Non-modular: single `AppRouter` at `lib/app_router.dart`
- Modular: per-feature `@AutoRouterConfig()` + RouteProvider abstraction
- Route providers enable cross-feature navigation without direct imports
- `replaceInRouteName: 'Page,Route'` — `LoginPage` becomes `LoginRoute`
- Run code generation after adding routes: `build_runner build`
- Register `AppRouter` in DI before `getIt.init()`

### References

- `${UFIL_ROOT}/docs/ROUTING.md` — Route provider patterns for navigation
- `${UFIL_ROOT}/docs/PRESENTATION_LAYER.md` — Presentation layer structure
