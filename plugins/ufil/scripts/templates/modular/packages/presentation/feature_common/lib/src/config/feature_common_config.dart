import 'package:feature_common/src/di/di.dart';
import 'package:library_common/library_common.dart';

class FeatureCommonConfig extends AppConfig {
  FeatureCommonConfig._();

  factory FeatureCommonConfig.getInstance() {
    return _instance;
  }

  static final FeatureCommonConfig _instance = FeatureCommonConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
