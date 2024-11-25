import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyDeviceToken = "deviceToken";
  static const String _keyLat = "lat";
  static const String _keyLong = "long";
  static const String _keyEmployeeId = "employeeId";
  static const String _keyLocationData = "locationData";

  /// Initialize SharedPreferences
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Save Device Token
  static Future<void> setDeviceToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyDeviceToken, token);
  }

  static Future<String?> getDeviceToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyDeviceToken);
  }

  /// Save Latitude
  static Future<void> setLatitude(double lat) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyLat, lat);
  }

  static Future<double?> getLatitude() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyLat);
  }

  /// Save Longitude
  static Future<void> setLongitude(double long) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyLong, long);
  }

  static Future<double?> getLongitude() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_keyLong);
  }

  /// Save Employee ID
  static Future<void> setEmployeeId(int id) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyEmployeeId, id);
  }

  static Future<int?> getEmployeeId() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyEmployeeId);
  }

  /// Save Location ID
  /// Save a JSON string (already serialized)
  static Future<void> setLocationData(String jsonString) async {
    final prefs = await _getPrefs();
    await prefs.setString(
        _keyLocationData, jsonString); // Save the JSON string directly
  }

  /// Retrieve a JSON string (serialized map)
  static Future<String?> getLocationData() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyLocationData); // Return the JSON string
  }

  /// Clear All Stored Data
  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  /// Clear Specific Key
  static Future<void> removeKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }
}
