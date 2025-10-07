import 'package:xingmubiao/src/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 跳过Firebase初始化，直接初始化通知服务
      await NotificationService().init();
      
      _initialized = true;
      debugPrint('Services initialized successfully (Firebase disabled)');
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // 即使通知服务初始化失败，也标记为已初始化
      _initialized = true;
    }
  }
  
  static bool get isInitialized => _initialized;
}
