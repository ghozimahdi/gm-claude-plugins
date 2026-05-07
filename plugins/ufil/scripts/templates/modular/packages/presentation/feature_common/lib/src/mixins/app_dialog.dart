import 'package:feature_common/feature_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

mixin AppDialog {
  Future<void> showCustomDialog(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? padding,
  }) async {
    await showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (_) {
        return Dialog(
          surfaceTintColor: colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          backgroundColor: colors.white,
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> showAlertDialog(
    BuildContext context, {
    Widget? title,
    required Widget Function(BuildContext context) content,
    required List<TextButton> Function(BuildContext context) actions,
    bool barrierDismissible = false,
    ShapeBorder? shape,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(20.r),
          shape: shape,
          title: title,
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: content(context),
          ),
          actions: actions(context),
        );
      },
    );
  }
}
