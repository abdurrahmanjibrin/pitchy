import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final SharedPreferences _prefs;

  UserRepository(this._prefs);

  static Future<UserRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRepository(prefs);
  }

  String getUserName() {
    return _prefs.getString(AppConstants.prefUserName) ?? 'Mahasiswa';
  }

  Future<void> saveUserName(String name) async {
    await _prefs.setString(AppConstants.prefUserName, name.trim());
  }

  bool isOnboardingCompleted() {
    return _prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(AppConstants.prefOnboardingCompleted, completed);
  }

  String? getApiKey() {
    return _prefs.getString(AppConstants.prefApiKey);
  }

  Future<void> saveApiKey(String key) async {
    await _prefs.setString(AppConstants.prefApiKey, key.trim());
  }

  Future<void> clearApiKey() async {
    await _prefs.remove(AppConstants.prefApiKey);
  }

  bool useLocalSttFallback() {
    return _prefs.getBool(AppConstants.prefUseLocalSttFallback) ?? false;
  }

  Future<void> setUseLocalSttFallback(bool val) async {
    await _prefs.setBool(AppConstants.prefUseLocalSttFallback, val);
  }

  Future<void> resetAll() async {
    await _prefs.clear();
  }
}

