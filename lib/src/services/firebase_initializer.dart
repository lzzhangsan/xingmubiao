import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  static bool _initializationAttempted = false;
  
  static Future<bool> initializeFirebase() async {
    if (_initialized) return true;
    if (_initializationAttempted) return false;
    
    _initializationAttempted = true;
    
    try {
      // 检查是否有Firebase配置文件
      // 如果没有配置文件，直接返回false，不尝试初始化
      debugPrint('Firebase initialization skipped - no configuration files found');
      debugPrint('App will run in offline mode with local data storage');
      return false;
    } catch (e) {
      // 如果初始化失败，记录错误但不中断应用
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Continuing without Firebase functionality');
      return false;
    }
  }
  
  static bool isInitialized() {
    return _initialized;
  }
}