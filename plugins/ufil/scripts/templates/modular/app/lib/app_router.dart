import 'package:auto_route/auto_route.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_common/feature_common.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
  ];
}

/// A custom route builder function for displaying a modal bottom sheet.
///
/// This function is designed to work with `CustomRoute` in AutoRoute to display
/// a modal bottom sheet with specific styles and behavior.
///
/// Example Usage in AutoRoute:
/// ```dart
/// CustomRoute(
///   page: SomePage.page,
///   customRouteBuilder: modalSheetBuilder,
/// ),
/// ```
Route<T> modalSheetBuilder<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
) {
  return ModalBottomSheetRoute<T>(
    settings: page,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ),
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.r),
        topRight: Radius.circular(16.r),
      ),
    ),
    backgroundColor: colors.white,
    elevation: 0,
  );
}
