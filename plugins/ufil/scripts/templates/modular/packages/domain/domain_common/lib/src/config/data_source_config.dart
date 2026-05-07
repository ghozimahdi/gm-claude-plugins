abstract interface class DataSourceConfig {
  abstract final String baseUrl;

  // Firebase keys
  abstract final String firebaseMessagingSenderId;
  abstract final String firebaseProjectId;
  abstract final String firebaseStorageBucket;

  abstract final String androidFirebaseApiKey;
  abstract final String androidFirebaseAppId;

  abstract final String iosFirebaseApiKey;
  abstract final String iosFirebaseAppId;
  abstract final String iosFirebaseBundleId;
  abstract final String iosFirebaseClientId;
}
