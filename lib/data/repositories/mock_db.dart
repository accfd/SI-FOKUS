import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MockDb {
  MockDb._();
  
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> save(String collection, String id, Map<String, dynamic> data) async {
    await init();
    final list = _prefs!.getStringList(collection) ?? [];
    
    // Hapus jika ID sudah ada untuk mencegah duplikasi
    list.removeWhere((item) {
      final decoded = json.decode(item) as Map<String, dynamic>;
      final matchId = decoded['interventionId'] ??
                      decoded['assessmentId'] ?? 
                      decoded['materialId'] ?? 
                      decoded['classId'] ?? 
                      decoded['uid'] ?? 
                      decoded['id'];
      return matchId == id;
    });

    list.add(json.encode(data));
    await _prefs!.setStringList(collection, list);
  }

  static Future<Map<String, dynamic>?> get(String collection, String id) async {
    await init();
    final list = _prefs!.getStringList(collection) ?? [];
    for (final item in list) {
      final decoded = json.decode(item) as Map<String, dynamic>;
      final matchId = decoded['interventionId'] ??
                      decoded['assessmentId'] ?? 
                      decoded['materialId'] ?? 
                      decoded['classId'] ?? 
                      decoded['uid'] ?? 
                      decoded['id'];
      if (matchId == id) {
        return decoded;
      }
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAll(String collection) async {
    await init();
    final list = _prefs!.getStringList(collection) ?? [];
    return list.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  static Future<void> delete(String collection, String id) async {
    await init();
    final list = _prefs!.getStringList(collection) ?? [];
    list.removeWhere((item) {
      final decoded = json.decode(item) as Map<String, dynamic>;
      final matchId = decoded['interventionId'] ??
                      decoded['assessmentId'] ?? 
                      decoded['materialId'] ?? 
                      decoded['classId'] ?? 
                      decoded['uid'] ?? 
                      decoded['id'];
      return matchId == id;
    });
    await _prefs!.setStringList(collection, list);
  }

  static Future<void> setString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  static Future<void> remove(String key) async {
    await init();
    await _prefs!.remove(key);
  }
}
