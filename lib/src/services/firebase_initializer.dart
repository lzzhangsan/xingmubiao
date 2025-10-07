import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  static bool _initializationAttempted = false;

  static Future<bool> initializeFirebase() async {
    if (_initialized) {
      return true;
    }
    if (_initializationAttempted) {
      return _initialized;
    }

    _initializationAttempted = true;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('Firebase 初始化成功');
    } catch (e) {
      debugPrint('Firebase 初始化失败或未配置，将以离线模式运行：$e');
      _initialized = false;
    }
    return _initialized;
  }

  static bool isInitialized() => _initialized;
}
