import 'package:async/async.dart';

abstract class AppConfig {
  final _asyncMemoizer = AsyncMemoizer<bool>();

  Future<bool> config({required String env});

  Future<bool> init({required String env}) =>
      _asyncMemoizer.runOnce(() => config(env: env));
}
