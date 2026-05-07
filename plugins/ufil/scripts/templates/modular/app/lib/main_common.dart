import 'dart:async';
import 'dart:ui';

import 'package:app/app_router.dart';
import 'package:app/injector.dart';
import 'package:auto_route/auto_route.dart';
import 'package:data_common/data_common.dart';
import 'package:feature_common/feature_common.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:library_common/library_common.dart';

Future<void> mainCommon(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load(const Locale('en'));

  await AppEnv.initialize(flavor);
  await configureDependencies(environment: flavor.environment);

  // Uncomment the following code to enable Firebase functionality.
  // For detailed documentation, refer to the .firebase folder in the app directory.
  // await FirebaseHelper.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (flavor == Flavor.prod || flavor == Flavor.staging) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: true,
      );
      return true;
    };

    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = WidgetsBinding.instance.platformDispatcher.locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  final _appRouter = getIt<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: ScreenUtilInit(
        // TODO: Please ensure this follows your Figma guidelines
        //  and aligns with the base frame used in your Figma design.
        designSize: const Size(360, 768),
        builder: (context, child) {
          return MaterialApp.router(
            routerConfig: _appRouter.config(
              navigatorObservers: () => [
                ChuckerFlutter.navigatorObserver,
                AutoRouteObserver(),
              ],
            ),
            title: AppEnv.title,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: _locale,
            theme: lightTheme,
            builder: (context, child) => Overlay(
              initialEntries: [
                if (child != null) ...[
                  OverlayEntry(
                    builder: (context) {
                      return MediaQuery.withClampedTextScaling(
                        minScaleFactor: 1,
                        maxScaleFactor: 1,
                        child: FlavorBanner(
                          child: GestureDetector(
                            child: child,
                            onTap: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
