import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      // 在开发环境中，我们可以使用模拟数据
      _initialized = true;
    }
  }
  
  static bool get isInitialized => _initialized;
}