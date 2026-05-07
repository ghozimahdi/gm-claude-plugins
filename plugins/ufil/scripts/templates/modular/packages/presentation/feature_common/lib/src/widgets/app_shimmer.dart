import 'package:feature_common/src/themes/color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final double borderRadius;

  const AppShimmer({super.key, this.borderRadius = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.lightGray,
      highlightColor: colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: const BoxDecoration(color: colors.lightGray),
        ),
      ),
    );
  }
}
