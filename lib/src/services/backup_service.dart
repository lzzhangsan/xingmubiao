import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class BackupService {
  static Future<void> exportAll() async {
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

    final archive = Archive();
    final bytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('xingmubiao_data.json', bytes.length, bytes));
    final zipBytes = ZipEncoder().encode(archive)!;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/xingmubiao_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(zipBytes);

    await Share.shareXFiles([XFile(file.path)], text: '星目标数据备份');
  }

  static Future<bool> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final path = result.files.single.path;
    if (path == null) return false;

    String jsonStr;
    if (path.toLowerCase().endsWith('.zip')) {
      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('xingmubiao_data.json');
      if (file == null) return false;
      jsonStr = utf8.decode(file.content as List<int>);
    } else {
      jsonStr = await File(path).readAsString();
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
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
