import 'package:data_common/src/di/di.dart';
import 'package:library_common/library_common.dart';

class DataCommonConfig extends AppConfig {
  DataCommonConfig._();

  factory DataCommonConfig.getInstance() {
    return _instance;
  }

  static final DataCommonConfig _instance = DataCommonConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
