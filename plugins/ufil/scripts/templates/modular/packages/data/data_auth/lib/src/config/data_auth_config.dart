import 'package:data_auth/src/di/di.dart';
import 'package:library_common/library_common.dart';

class DataAuthConfig extends AppConfig {
  DataAuthConfig._();

  factory DataAuthConfig.getInstance() {
    return _instance;
  }

  static final DataAuthConfig _instance = DataAuthConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
