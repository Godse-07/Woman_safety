import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const String userTypeKey = "user_type";

  static Future<void> setUserType(String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userTypeKey, userType);
  }

  static Future<String?> getUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userTypeKey);
  }

  static Future<void> clearUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userTypeKey);
  }
}
