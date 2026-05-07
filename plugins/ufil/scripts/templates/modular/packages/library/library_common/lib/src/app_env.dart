import 'package:library_common/src/flavor.dart';

mixin AppEnv {
  static Flavor? _currentFlavor;

  static Future<void> initialize(Flavor flavor) async {
    _currentFlavor ??= flavor;
  }

  static String get flavorName => _currentFlavor?.name ?? '';

  static Flavor get flavor => _currentFlavor ?? Flavor.dev;

  static String get title {
    switch (_currentFlavor) {
      case Flavor.dev:
        return 'App Dev';
      case Flavor.staging:
        return 'App Staging';
      case Flavor.prod:
        return 'App Property';
      default:
        return '';
    }
  }
}
