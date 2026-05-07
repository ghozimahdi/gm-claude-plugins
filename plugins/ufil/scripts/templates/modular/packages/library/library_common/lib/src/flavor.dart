import 'package:injectable/injectable.dart';

enum Flavor { dev, staging, prod }

extension FlavorExt on Flavor {
  String get environment {
    switch (this) {
      case Flavor.dev:
        return Environment.dev;
      case Flavor.staging:
        return Environment.test;
      case Flavor.prod:
        return Environment.prod;
    }
  }

  bool get isDevelopment {
    return this == Flavor.dev || this == Flavor.staging;
  }
}
