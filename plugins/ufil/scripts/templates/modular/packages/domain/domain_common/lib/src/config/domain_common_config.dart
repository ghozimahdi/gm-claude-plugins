import 'package:domain_common/src/di/di.dart';
import 'package:library_common/library_common.dart';

class DomainCommonConfig extends AppConfig {
  DomainCommonConfig._();

  factory DomainCommonConfig.getInstance() {
    return _instance;
  }

  static final DomainCommonConfig _instance = DomainCommonConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
