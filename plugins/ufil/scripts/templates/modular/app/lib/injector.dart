import 'package:app/app_router.dart';
import 'package:app/injector.config.dart';
import 'package:data_auth/data_auth.dart';
import 'package:data_common/data_common.dart';
import 'package:domain_auth/domain_auth.dart';
import 'package:domain_common/domain_common.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_common/feature_common.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies({required String environment}) async {
  getIt.registerSingleton<AppRouter>(AppRouter());

  // TODO: Add injection here
  await DomainCommonConfig.getInstance().config(env: environment);
  DomainAuthConfig.getInstance().config(env: environment);

  await DataCommonConfig.getInstance().config(env: environment);
  DataAuthConfig.getInstance().config(env: environment);

  await FeatureCommonConfig.getInstance().config(env: environment);
  FeatureDashboardConfig.getInstance().config(env: environment);
  FeatureAuthConfig.getInstance().config(env: environment);

  getIt.init(environment: environment);
}
