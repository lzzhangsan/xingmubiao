import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  
  static Future<bool> initializeFirebase() async {
    if (_initialized) return true;
    
    try {
      // 尝试初始化Firebase
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('Firebase initialized successfully');
      return true;
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