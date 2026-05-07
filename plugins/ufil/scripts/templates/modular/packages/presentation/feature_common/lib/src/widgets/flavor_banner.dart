import 'package:flutter/material.dart';
import 'package:library_common/library_common.dart';

class FlavorBanner extends StatelessWidget {
  const FlavorBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppEnv.flavor != Flavor.prod
        ? Banner(
            location: BannerLocation.topStart,
            message: AppEnv.flavorName,
            color: Colors.green.withValues(alpha: 0.6),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.0,
              letterSpacing: 1.0,
            ),
            child: child,
          )
        : child;
  }
}
