import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/services/user_service.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class AppProvider with ChangeNotifier {
  AppProvider() {
    _init();
  }

  static const _selectedChildKey = 'selected_child_id';

  List<User> _users = [];
  String? _selectedChildId;
  bool _initialized = false;

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
    _initialized = true;
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
