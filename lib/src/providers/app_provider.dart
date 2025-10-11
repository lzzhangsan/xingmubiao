import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/services/user_service.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';
import 'package:flutter/material.dart' show Color;

enum ThemeStyle { day, night, simple, cool, custom }

enum AnimationIntensity { off, low, medium, high }

class AppProvider with ChangeNotifier {
  AppProvider() {
    _init();
  }

  static const _selectedChildKey = 'selected_child_id';

  List<User> _users = [];
  String? _selectedChildId;
  bool _initialized = false;

  // Theme related
  ThemeStyle _themeStyle = ThemeStyle.day;
  String? _customBgColorHex;
  String? _customBgImage; // could be a URL or local path
  AnimationIntensity _animationIntensity = AnimationIntensity.medium;

  ThemeStyle get themeStyle => _themeStyle;
  String? get customBgColorHex => _customBgColorHex;
  String? get customBgImage => _customBgImage;
  AnimationIntensity get animationIntensity => _animationIntensity;

  List<User> get users => _users;

  List<User> get children =>
      _users.where((user) => user.role == 'child').toList();

  User? get selectedChild {
    if (_selectedChildId == null) return null;
    try {
      return children.firstWhere((child) => child.id == _selectedChildId);
    } catch (_) {
      return children.isNotEmpty ? children.first : null;
    }
  }

  bool get isInitialized => _initialized;

  Future<void> _init() async {
    await UserService.ensureDefaultUsers();
    await _loadUsers();
    await _loadSelectedChild();
    await _loadThemeSettings();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadThemeSettings() async {
    String themeKey = _prefixedKey('theme_style');
    String colorKey = _prefixedKey('custom_bg_color');
    String imageKey = _prefixedKey('custom_bg_image');
    String animKey = _prefixedKey('anim_intensity');

    final style = await LocalDataStore.getString(themeKey);
    if (style != null) {
      try {
        _themeStyle = ThemeStyle.values.firstWhere((e) => e.toString().split('.').last == style);
      } catch (_) {
        _themeStyle = ThemeStyle.day;
      }
    }
    _customBgColorHex = await LocalDataStore.getString(colorKey);
    _customBgImage = await LocalDataStore.getString(imageKey);
    final anim = await LocalDataStore.getString(animKey);
    if (anim != null) {
      try {
        _animationIntensity = AnimationIntensity.values.firstWhere((e) => e.toString().split('.').last == anim);
      } catch (_) {
        _animationIntensity = AnimationIntensity.high;
      }
    }
  }

  String _prefixedKey(String key) {
    if (_selectedChildId == null) return key;
    return '${_selectedChildId}_$key';
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    if (_themeStyle == style) return;
    _themeStyle = style;
    await LocalDataStore.setString(_prefixedKey('theme_style'), style.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setCustomBgColorHex(String? hex) async {
    _customBgColorHex = hex;
    if (hex == null) {
      await LocalDataStore.clearKey(_prefixedKey('custom_bg_color'));
    } else {
      await LocalDataStore.setString(_prefixedKey('custom_bg_color'), hex);
    }
    notifyListeners();
  }

  Future<void> setCustomBgImage(String? image) async {
    _customBgImage = image;
    if (image == null) {
      await LocalDataStore.clearKey(_prefixedKey('custom_bg_image'));
    } else {
      await LocalDataStore.setString(_prefixedKey('custom_bg_image'), image);
    }
    notifyListeners();
  }

  Future<void> setAnimationIntensity(AnimationIntensity intensity) async {
    _animationIntensity = intensity;
    await LocalDataStore.setString(_prefixedKey('anim_intensity'), intensity.toString().split('.').last);
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    _users = await UserService.getUsers();
  }

  Future<void> _loadSelectedChild() async {
    final savedId = await LocalDataStore.getString(_selectedChildKey);
    final childExists = savedId != null &&
        children.any((child) => child.id == savedId);
    if (childExists) {
      _selectedChildId = savedId;
    } else if (children.isNotEmpty) {
      _selectedChildId = children.first.id;
      await LocalDataStore.setString(_selectedChildKey, _selectedChildId!);
    } else {
      _selectedChildId = null;
    }
  }

  Future<void> refreshUsers() async {
    await _loadUsers();
    await _loadSelectedChild();
    notifyListeners();
  }

  Future<void> setSelectedChildId(String childId) async {
    if (_selectedChildId == childId) return;
    _selectedChildId = childId;
    await LocalDataStore.setString(_selectedChildKey, childId);
    // load settings for the newly selected child
    await _loadThemeSettings();
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    await UserService.addUser(user);
    await refreshUsers();
    if (user.role == 'child') {
      await setSelectedChildId(user.id);
    }
  }

  Future<void> removeUser(String userId) async {
    await UserService.deleteUser(userId);
    await refreshUsers();
  }
}
