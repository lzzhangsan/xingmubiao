import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class BackupService {
  static Future<void> exportAll({ValueNotifier<String>? progress}) async {
    progress?.value = '正在准备数据...';
    await LocalDataStore.init();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (final key in keys) {
      data[key] = prefs.get(key);
    }

    final imageMap = <String, String>{}; // rel -> absolute
    int imageIndex = 0;

    void processList(String key, List<String> fields) {
      final raw = data[key];
      if (raw is! String) return;
      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            for (final f in fields) {
              if (f == 'imageUrls') {
                final urls = (item['imageUrls'] as List?)?.cast<String>() ?? [];
                final newUrls = <String>[];
                for (final u in urls) {
                  if (u.isNotEmpty && File(u).existsSync()) {
                    final ext = u.contains('.') ? u.substring(u.lastIndexOf('.')) : '.jpg';
                    final rel = 'images/img_$imageIndex$ext';
                    imageMap[rel] = u;
                    newUrls.add(rel);
                    imageIndex++;
                  }
                }
                item['imageUrls'] = newUrls;
                if (newUrls.isNotEmpty) item['imageUrl'] = newUrls.first;
              } else {
                final path = item[f] as String?;
                if (path != null && path.isNotEmpty && File(path).existsSync()) {
                  final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
                  final rel = 'images/img_$imageIndex$ext';
                  imageMap[rel] = path;
                  item[f] = rel;
                  imageIndex++;
                }
              }
            }
          }
        }
        data[key] = jsonEncode(list);
      } catch (_) {}
    }

    processList('users', ['avatarUrl']);
    processList('checkins', ['imageUrls']);

    // Collect custom background images (keys containing custom_bg_image)
    for (final key in data.keys.toList()) {
      if (key.contains('custom_bg_image')) {
        final path = data[key] as String?;
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '.jpg';
          final rel = 'images/bg_$imageIndex$ext';
          imageMap[rel] = path;
          data[key] = rel;
          imageIndex++;
        }
      }
    }

    progress?.value = '正在打包数据...';
    final jsonStr = jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });

    final dir = await getTemporaryDirectory();
    final zipPath = '${dir.path}/xingmubiao_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('xingmubiao_data.json', jsonBytes.length, jsonBytes));

    int done = 0;
    for (final entry in imageMap.entries) {
      final file = File(entry.value);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
      }
      done++;
      if (done % 5 == 0 || done == imageMap.length) {
        progress?.value = '正在打包图片 $done/${imageMap.length}...';
      }
    }
    final zipBytes = ZipEncoder().encode(archive)!;
    await File(zipPath).writeAsBytes(zipBytes);

    progress?.value = '已准备分享';
    await Share.shareXFiles([XFile(zipPath)], text: '星目标数据备份');
  }

  static Future<bool> importAll({ValueNotifier<String>? progress}) async {
    progress?.value = '请选择备份文件';
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final path = result.files.single.path;
    if (path == null) return false;

    progress?.value = '正在读取备份...';
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

    if (archive != null) {
      progress?.value = '正在还原图片...';
      final appDir = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${appDir.path}/backup_images');
      if (!imgDir.existsSync()) imgDir.createSync(recursive: true);

      final pathMap = <String, String>{};
      int imgCount = 0;
      for (final file in archive.files) {
        if (file.name.startsWith('images/')) {
          final localPath = '${imgDir.path}/${file.name.substring(7)}';
          await File(localPath).writeAsBytes(file.content as List<int>);
          pathMap[file.name] = localPath;
          imgCount++;
          if (imgCount % 5 == 0) progress?.value = '正在还原图片 $imgCount...';
        }
      }

      void rewrite(String key) {
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
      rewrite('users');
      rewrite('checkins');

      // Rewrite background image paths
      for (final key in data.keys.toList()) {
        if (key.contains('custom_bg_image')) {
          final rel = data[key] as String?;
          if (rel != null && pathMap.containsKey(rel)) {
            data[key] = pathMap[rel];
          }
        }
      }
    }

    progress?.value = '正在写入数据...';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String) await prefs.setString(entry.key, value);
      else if (value is int) await prefs.setInt(entry.key, value);
      else if (value is double) await prefs.setDouble(entry.key, value);
      else if (value is bool) await prefs.setBool(entry.key, value);
      else if (value is List) await prefs.setStringList(entry.key, value.cast<String>());
    }
    progress?.value = '导入完成';
    return true;
  }
}
