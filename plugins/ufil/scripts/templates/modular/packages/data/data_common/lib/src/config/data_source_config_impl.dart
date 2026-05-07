import 'package:domain_common/domain_common.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DataSourceConfig, env: [Environment.dev, Environment.test])
class DevDataSourceConfig implements DataSourceConfig {
  @override
  String get baseUrl => 'https://www.dev.ghozimahdi.com';

  @override
  // TODO: implement androidFirebaseApiKey
  String get androidFirebaseApiKey => throw UnimplementedError();

  @override
  // TODO: implement androidFirebaseAppId
  String get androidFirebaseAppId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseApiKey
  String get iosFirebaseApiKey => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseAppId
  String get iosFirebaseAppId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseBundleId
  String get iosFirebaseBundleId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseClientId
  String get iosFirebaseClientId => throw UnimplementedError();

  @override
  // TODO: implement firebaseMessagingSenderId
  String get firebaseMessagingSenderId => throw UnimplementedError();

  @override
  // TODO: implement firebaseProjectId
  String get firebaseProjectId => throw UnimplementedError();

  @override
  // TODO: implement firebaseStorageBucket
  String get firebaseStorageBucket => throw UnimplementedError();
}

@LazySingleton(as: DataSourceConfig, env: [Environment.prod])
class ProdDataSourceConfig implements DataSourceConfig {
  @override
  String get baseUrl => 'https://www.ghozimahdi.com';

  @override
  // TODO: implement androidFirebaseApiKey
  String get androidFirebaseApiKey => throw UnimplementedError();

  @override
  // TODO: implement androidFirebaseAppId
  String get androidFirebaseAppId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseApiKey
  String get iosFirebaseApiKey => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseAppId
  String get iosFirebaseAppId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseBundleId
  String get iosFirebaseBundleId => throw UnimplementedError();

  @override
  // TODO: implement iosFirebaseClientId
  String get iosFirebaseClientId => throw UnimplementedError();

  @override
  // TODO: implement firebaseMessagingSenderId
  String get firebaseMessagingSenderId => throw UnimplementedError();

  @override
  // TODO: implement firebaseProjectId
  String get firebaseProjectId => throw UnimplementedError();

  @override
  // TODO: implement firebaseStorageBucket
  String get firebaseStorageBucket => throw UnimplementedError();
}
