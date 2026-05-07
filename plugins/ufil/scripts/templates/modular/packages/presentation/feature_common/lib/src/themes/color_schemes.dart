import 'package:feature_common/generated/colors.gen.dart';
import 'package:flutter/material.dart';

const ColorScheme lightColorSchemes = ColorScheme.light(
  primary: colors.primary,
  secondary: colors.secondary,
  outline: colors.gray,
  tertiary: colors.tertiary,
);

const ColorScheme darkColorSchemes = ColorScheme.dark(
  primary: colors.primary,
  secondary: colors.secondary,
  outline: colors.gray,
  tertiary: colors.tertiary,
);

extension ColorThemeExt on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension ColorSchemeExt on ColorScheme {
  Color get appDivider => secondary.withAlpha(30);

  Color get primaryText => secondary;

  Color get secondaryText => tertiary;
}

// ignore: camel_case_types
typedef colors = AppColors;
