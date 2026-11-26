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

    // Collect image files and rewrite paths to relative
    final imageFiles = <String, File>{};
    int imageIndex = 0;

    void collectAndRewrite(Map<String, dynamic> item, String field) {
      final path = item[field] as String?;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
        final rel = 'images/img_$imageIndex$ext';
        imageFiles[rel] = File(path);
        item[field] = rel;
        imageIndex++;
      }
    }

    void processList(String key, List<String> fields) {
      final raw = data[key];
      if (raw is! String) return;
      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            for (final f in fields) {
              if (f == 'imageUrls') {
                final urls = item['imageUrls'] as List? ?? [];
                final newUrls = <String>[];
                for (final u in urls) {
                  if (u is String && u.isNotEmpty && File(u).existsSync()) {
                    final ext = u.contains('.') ? u.substring(u.lastIndexOf('.')) : '.jpg';
                    final rel = 'images/img_$imageIndex$ext';
                    imageFiles[rel] = File(u);
                    newUrls.add(rel);
                    imageIndex++;
                  } else {
                    newUrls.add(u.toString());
                  }
                }
                item['imageUrls'] = newUrls;
                if (newUrls.isNotEmpty) item['imageUrl'] = newUrls.first;
              } else {
                collectAndRewrite(item, f);
              }
            }
          }
        }
        data[key] = jsonEncode(list);
      } catch (_) {}
    }

    processList('users', ['avatarUrl']);
    processList('checkins', ['imageUrls']);

    final jsonStr = jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });

    final archive = Archive();
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('xingmubiao_data.json', jsonBytes.length, jsonBytes));

    for (final entry in imageFiles.entries) {
      final bytes = await entry.value.readAsBytes();
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

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
    Archive? archive;
    if (path.toLowerCase().endsWith('.zip')) {
      final bytes = await File(path).readAsBytes();
      archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('xingmubiao_data.json');
      if (file == null) return false;
      jsonStr = utf8.decode(file.content as List<int>);
    } else {
      jsonStr = await File(path).readAsString();
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = Map<String, dynamic>.from(decoded['data'] as Map? ?? {});

    // Restore images if present
    if (archive != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${appDir.path}/backup_images');
      if (!imgDir.existsSync()) imgDir.createSync(recursive: true);

      final pathMap = <String, String>{};
      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final localPath = '${imgDir.path}/${file.name.substring(7)}';
          await File(localPath).writeAsBytes(file.content as List<int>);
          pathMap[file.name] = localPath;
        }
      }

      // Rewrite relative paths back to local absolute paths
      void rewriteList(String key) {
        final raw = data[key];
        if (raw is! String) return;
        try {
          final list = jsonDecode(raw) as List;
          for (final item in list) {
            if (item is Map) {
              final avatar = item['avatarUrl'] as String?;
              if (avatar != null && pathMap.containsKey(avatar)) {
                item['avatarUrl'] = pathMap[avatar];
              }
              final urls = item['imageUrls'] as List?;
              if (urls != null) {
                final newUrls = urls.map((u) => pathMap[u.toString()] ?? u).toList();
                item['imageUrls'] = newUrls;
                if (newUrls.isNotEmpty) item['imageUrl'] = newUrls.first;
              }
            }
          }
          data[key] = jsonEncode(list);
        } catch (_) {}
      }

      rewriteList('users');
      rewriteList('checkins');
    }

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
