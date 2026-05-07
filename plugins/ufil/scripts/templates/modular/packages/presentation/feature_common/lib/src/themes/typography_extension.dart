import 'package:flutter/material.dart';

extension HeadlineTextThemeExt on TextTheme {
  TextStyle? get headlineLargeSemiBold =>
      headlineLarge?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get headlineLargeBold =>
      headlineLarge?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get headlineLargeRegular => headlineLarge;

  TextStyle? get headlineMediumSemiBold =>
      headlineMedium?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get headlineMediumBold =>
      headlineMedium?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get headlineMediumRegular => headlineMedium;

  TextStyle? get headlineSmallSemiBold =>
      headlineSmall?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get headlineSmallBold =>
      headlineSmall?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get headlineSmallRegular => headlineSmall;
}

extension CaptionTextThemeExt on TextTheme {
  TextStyle? get captionMedium =>
      labelSmall?.copyWith(fontWeight: FontWeight.w500);

  TextStyle? get captionRegular => labelSmall;

  TextStyle? get captionSemiBold =>
      labelSmall?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get captionBold =>
      labelSmall?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get captionUnderline => labelSmall?.copyWith(
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
    decorationThickness: 1,
  );
}

extension TitleTextThemeExt on TextTheme {
  TextStyle? get titleSmallMedium =>
      titleSmall?.copyWith(fontWeight: FontWeight.w500);

  TextStyle? get titleLargeBold =>
      titleLarge?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get titleSmallSemiBold =>
      titleSmall?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get titleSmallBold =>
      titleSmall?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get titleMediumSemiBold =>
      titleMedium?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get titleSmallRegular => titleSmall;

  TextStyle? get titleMediumRegular => titleMedium;
}

extension BodyTextThemeExt on TextTheme {
  TextStyle? get bodyLargeSemiBold =>
      bodyLarge?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get bodyLargeBold =>
      bodyLarge?.copyWith(fontWeight: FontWeight.w700);

  TextStyle? get bodyLargeMedium =>
      bodyLarge?.copyWith(fontWeight: FontWeight.w500);

  TextStyle? get bodySmallMedium =>
      bodySmall?.copyWith(fontWeight: FontWeight.w500);

  TextStyle? get bodySmallSemiBold =>
      bodySmall?.copyWith(fontWeight: FontWeight.w600);

  TextStyle? get bodySmallRegular => bodySmall;

  TextStyle? get bodySmallUnderline => bodySmall?.copyWith(
    decoration: TextDecoration.underline,
    decorationThickness: 1,
  );

  TextStyle? get bodyLargeRegular => bodyLarge;
}

extension TextThemeExt on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
