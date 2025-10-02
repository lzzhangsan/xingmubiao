import 'package:firebase_core/firebase_core.dart';
import 'package:xingmubiao/src/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      
      // 初始化通知服务
      await NotificationService().init();
      
      _initialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      // 在开发环境中，我们可以使用模拟数据
      await NotificationService().init();
      _initialized = true;
    }
  }
  
  static bool get isInitialized => _initialized;
}