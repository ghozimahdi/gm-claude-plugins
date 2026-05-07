import 'package:feature_common/generated/fonts.gen.dart';
import 'package:feature_common/src/themes/color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final textTheme =
    TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 32.sp),
      headlineMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 24.sp),
      headlineSmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 22.sp),
      titleLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 20.sp),
      titleMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 18.sp),
      titleSmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 16.sp),
      bodyLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 14.sp),
      bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12.sp),
      labelSmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 10.sp),
    ).apply(
      fontFamily: AppFonts.inter,
      bodyColor: colors.black,
      displayColor: colors.black,
    );
