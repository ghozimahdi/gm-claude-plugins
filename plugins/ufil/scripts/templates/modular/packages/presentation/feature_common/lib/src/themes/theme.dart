import 'package:feature_common/feature_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
  colorScheme: lightColorSchemes,
  textTheme: textTheme.apply(
    bodyColor: colors.primaryText,
    displayColor: colors.primaryText,
  ),
  scaffoldBackgroundColor: lightColorSchemes.surface,
  dividerColor: lightColorSchemes.outline,
  listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
  iconTheme: IconThemeData(color: lightColorSchemes.onSecondary),
  dividerTheme: DividerThemeData(
    thickness: 1,
    color: lightColorSchemes.outline,
    space: 1,
  ),
  checkboxTheme: CheckboxThemeData(
    side: BorderSide(color: lightColorSchemes.primary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
  ),
  appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
  badgeTheme: BadgeThemeData(
    backgroundColor: lightColorSchemes.tertiary,
    textColor: lightColorSchemes.surface,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightColorSchemes.surface,
    elevation: 4.dm,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedItemColor: lightColorSchemes.primary,
    unselectedItemColor: lightColorSchemes.tertiary,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: textTheme.captionMedium?.copyWith(
      color: lightColorSchemes.primary,
    ),
    unselectedLabelStyle: textTheme.captionRegular?.copyWith(
      color: lightColorSchemes.tertiary,
    ),
  ),
  tabBarTheme: TabBarThemeData(
    splashFactory: NoSplash.splashFactory,
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorColor: lightColorSchemes.secondary,
    dividerColor: colors.lightGray,
    unselectedLabelColor: lightColorSchemes.primary,
    unselectedLabelStyle: textTheme.bodySmallRegular,
    labelColor: lightColorSchemes.secondary,
    labelStyle: textTheme.bodySmallMedium,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: FilledButton.styleFrom(
      disabledBackgroundColor: colors.white,
      disabledForegroundColor: colors.sidebar,
      foregroundColor: colors.white,
      backgroundColor: lightColorSchemes.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      textStyle: textTheme.titleSmallSemiBold,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      disabledBackgroundColor: colors.white,
      disabledForegroundColor: colors.sidebar,
      foregroundColor: colors.white,
      backgroundColor: lightColorSchemes.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      textStyle: textTheme.bodyLargeSemiBold,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style:
        OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          textStyle: textTheme.bodyLargeSemiBold,
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
          disabledBackgroundColor: colors.disabled,
          disabledForegroundColor: colors.disabled,
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: colors.disabled);
            }
            return BorderSide(color: lightColorSchemes.primary);
          }),
        ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: colors.sidebar,
      textStyle: textTheme.bodyLargeSemiBold,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.h),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: colors.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: colors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: BorderSide(color: lightColorSchemes.primary),
    ),
    prefixStyle: textTheme.bodyLarge?.copyWith(color: colors.black),
    labelStyle: textTheme.bodyLarge?.copyWith(color: colors.black),
    hintStyle: textTheme.bodyLarge?.copyWith(color: colors.placeholder),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6.r),
      borderSide: const BorderSide(color: colors.disabled),
    ),
    fillColor: colors.white,
    filled: true,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    foregroundColor: lightColorSchemes.surface,
    backgroundColor: lightColorSchemes.primary,
    extendedSizeConstraints: BoxConstraints(minHeight: 44.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
  ),
  searchBarTheme: SearchBarThemeData(
    padding: WidgetStateProperty.all(EdgeInsets.only(left: 8.w, right: 16.w)),
    shadowColor: WidgetStateProperty.all(colors.gray.withAlpha(50)),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: lightColorSchemes.primary,
    textTheme: ButtonTextTheme.primary,
  ),
);
