import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static SharedPreferences? _sharedPref;
  static const String key = 'userType';

  static Future<void> init() async {
    _sharedPref = await SharedPreferences.getInstance();
  }

  static Future<bool> saveUserType(String type) async {
    if (_sharedPref == null) {
      await init();
    }
    return await _sharedPref!.setString(key, type);
  }

  static Future<String>? getUserType() async =>await _sharedPref?.getString(key) ?? "";
}