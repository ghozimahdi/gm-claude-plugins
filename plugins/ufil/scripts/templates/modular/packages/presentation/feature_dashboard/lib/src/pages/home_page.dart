import 'package:auto_route/auto_route.dart';
import 'package:feature_common/feature_common.dart';
import 'package:feature_dashboard/src/config/feature_dashboard_route.gr.dart';
import 'package:feature_dashboard/src/di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: HomeRouteProvider)
class HomeRouteProviderImpl implements HomeRouteProvider {
  @override
  PageRouteInfo route() {
    return const HomeRoute();
  }
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.dm),
          child: Column(
            spacing: 16.h,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hello and welcome! Ghozi Mahdi CLI is a tool to manage your Flutter projects efficiently.',
                style: textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () {
                  context.pushRoute(getIt<LoginRouteProvider>().route());
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
