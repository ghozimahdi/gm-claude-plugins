import 'dart:async';

import 'package:app/main_common.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:library_common/library_common.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      await mainCommon(Flavor.prod);
    },
    (error, stackTrace) async {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    },
  );
}
