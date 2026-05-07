import 'package:feature_auth/src/di/di.dart';
import 'package:library_common/library_common.dart';

class FeatureAuthConfig extends AppConfig {
  FeatureAuthConfig._();

  factory FeatureAuthConfig.getInstance() {
    return _instance;
  }

  static final FeatureAuthConfig _instance = FeatureAuthConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
