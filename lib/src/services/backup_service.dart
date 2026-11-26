import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class BackupService {
  static Future<String?> exportAll() async {
    await LocalDataStore.init();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (final key in keys) {
      data[key] = prefs.get(key);
    }
    final jsonStr = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
    final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/xingmubiao_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    return file.path;
  }

  static Future<bool> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final path = result.files.single.path;
    if (path == null) return false;
    final content = await File(path).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.cast<String>());
      }
    }
    return true;
  }
}
