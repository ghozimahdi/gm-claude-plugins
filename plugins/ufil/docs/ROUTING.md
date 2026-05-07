# Routing Guidelines

This document describes the rules and conventions for routing using auto_route.

## Route Provider Pattern

The project uses a Route Provider pattern to enable navigation between features without direct dependencies.

### Architecture

```
feature_common (abstractions)
    │
    ├── LoginRouteProvider (abstract)
    ├── HomeRouteProvider (abstract)
    └── ProfileRouteProvider (abstract)
           │
           ▼
feature_auth (implementations)
    └── LoginRouteProviderImpl
           │
           ▼
feature_dashboard
    └── HomeRouteProviderImpl
```

## Creating a Route Provider

### Step 1: Create Abstract Class in feature_common

Location: `packages/presentation/feature_common/lib/src/route/`

```dart
// edit_profile_route_provider.dart
import 'package:auto_route/auto_route.dart';

/// Route provider for EditProfile page.
abstract class EditProfileRouteProvider {
  /// Returns the route to navigate to EditProfile page.
  PageRouteInfo route();
}
```

### Step 2: Export in feature_common.dart

```dart
// feature_common.dart
export 'src/route/edit_profile_route_provider.dart';
export 'src/route/login_route_provider.dart';
export 'src/route/home_route_provider.dart';
// ... other exports
```

### Step 3: Implement in Feature Module

Location: `packages/presentation/feature_setting/lib/src/pages/edit_profile_page.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:feature_common/feature_common.dart';
import 'package:feature_setting/src/config/feature_setting_route.gr.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: EditProfileRouteProvider)
class EditProfileRouteProviderImpl implements EditProfileRouteProvider {
  @override
  PageRouteInfo route() {
    return const EditProfileRoute();
  }
}

@RoutePage()
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
    );
  }
}
```

## Route Configuration

### Feature Route Config

```dart
// feature_auth_route.dart
import 'package:auto_route/auto_route.dart';

@AutoRouterConfig()
abstract class FeatureAuthRoute {}
```

### App Router

The main app router combines all feature routes:

```dart
// app/lib/app_router.dart
import 'package:auto_route/auto_route.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_dashboard/feature_dashboard.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: EditProfileRoute.page),
  ];
}
```

## Navigation

### Using Route Provider

```dart
class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final routeProvider = getIt<EditProfileRouteProvider>();
        context.router.push(routeProvider.route());
      },
      child: Text('Go to Edit Profile'),
    );
  }
}
```

### Direct Navigation (within same feature)

```dart
context.router.push(const EditProfileRoute());
```

## Page Annotations

Always use `@RoutePage()` annotation for pages:

```dart
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
    );
  }
}
```

## Route with Parameters

### Define Route with Parameters

```dart
@RoutePage()
class OrderDetailPage extends StatelessWidget {
  final String orderId;

  const OrderDetailPage({
    super.key,
    @PathParam('orderId') required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
    );
  }
}
```

### Route Provider with Parameters

```dart
abstract class OrderDetailRouteProvider {
  PageRouteInfo route({required String orderId});
}

@Injectable(as: OrderDetailRouteProvider)
class OrderDetailRouteProviderImpl implements OrderDetailRouteProvider {
  @override
  PageRouteInfo route({required String orderId}) {
    return OrderDetailRoute(orderId: orderId);
  }
}
```

## Build Commands

After creating or modifying route-related files:

### Format and Fix (in feature_common)

```bash
cd packages/presentation/feature_common
fvm dart format .
fvm dart fix --apply
```

### Build Runner (in feature module)

```bash
cd packages/presentation/feature_setting
fvm dart run build_runner build -d
```

## Checklist

When creating a new page with routing:

1. [ ] Create abstract route provider in `feature_common/lib/src/route/`
2. [ ] Export in `feature_common/lib/feature_common.dart`
3. [ ] Create page with `@RoutePage()` annotation
4. [ ] Implement route provider with `@Injectable(as: RouteProvider)`
5. [ ] Import the generated route file (`feature_xxx_route.gr.dart`)
6. [ ] Run format and fix in feature_common
7. [ ] Run build_runner in the feature module
8. [ ] Register route in app_router.dart (if needed)

## Common Issues

### Missing Route Class

If the route class is not found, ensure:
1. You've imported the generated file: `import 'package:feature_xxx/src/config/feature_xxx_route.gr.dart';`
2. You've run build_runner: `fvm dart run build_runner build -d`

### Route Provider Not Found

If the route provider is not injectable:
1. Check that `@Injectable(as: RouteProvider)` annotation is present
2. Ensure the DI is configured in `feature_xxx_config.dart`
3. Run build_runner to regenerate DI config
