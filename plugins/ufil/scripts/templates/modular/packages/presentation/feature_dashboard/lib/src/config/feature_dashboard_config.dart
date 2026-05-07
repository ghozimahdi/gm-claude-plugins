import 'package:feature_dashboard/src/di/di.dart';
import 'package:library_common/library_common.dart';

class FeatureDashboardConfig extends AppConfig {
  FeatureDashboardConfig._();

  factory FeatureDashboardConfig.getInstance() {
    return _instance;
  }

  static final FeatureDashboardConfig _instance = FeatureDashboardConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
