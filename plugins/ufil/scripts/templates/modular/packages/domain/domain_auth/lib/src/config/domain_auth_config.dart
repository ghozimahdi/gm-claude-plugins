import 'package:domain_auth/src/di/di.dart';
import 'package:library_common/library_common.dart';

class DomainAuthConfig extends AppConfig {
  DomainAuthConfig._();

  factory DomainAuthConfig.getInstance() {
    return _instance;
  }

  static final DomainAuthConfig _instance = DomainAuthConfig._();

  @override
  Future<bool> config({required String env}) async {
    await configureInjection(env: env);
    return true;
  }
}
