import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPreferenceDataSource {
  Future<void> setIsLogin(bool isLogin);

  bool getIsLogin();

  Future<bool> clearAllData();
}

@LazySingleton(as: SharedPreferenceDataSource)
class SharedPreferenceDataSourceImpl extends SharedPreferenceDataSource {
  final SharedPreferences sharedPreferences;

  SharedPreferenceDataSourceImpl(this.sharedPreferences);

  static const String isLoginKey = 'isLoginKey';

  @override
  bool getIsLogin() {
    return sharedPreferences.getBool(isLoginKey) ?? false;
  }

  @override
  Future<void> setIsLogin(bool isLogin) async {
    await sharedPreferences.setBool(isLoginKey, isLogin);
  }

  @override
  Future<bool> clearAllData() async {
    await sharedPreferences.clear();
    return true;
  }
}
