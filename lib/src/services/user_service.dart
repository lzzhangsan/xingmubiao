import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class UserService {
  static const _storageKey = 'users';
  static List<User> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final data = await LocalDataStore.loadList(_storageKey);
    _cache = data.map(User.fromJson).toList();
    _loaded = true;
  }

  static Future<void> _persist() async {
    await LocalDataStore.saveList(
      _storageKey,
      _cache.map((user) => user.toJson()).toList(),
    );
  }

  static Future<List<User>> getUsers() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  static Future<void> setUsers(List<User> users) async {
    _cache = List<User>.from(users);
    _loaded = true;
    await _persist();
  }

  static Future<void> addUser(User user) async {
    await _ensureLoaded();
    _cache.add(user);
    await _persist();
  }

  static Future<void> deleteUser(String userId) async {
    await _ensureLoaded();
    _cache.removeWhere((user) => user.id == userId);
    await _persist();
  }

  static Future<void> updateUser(User user) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _cache[index] = user;
      await _persist();
    }
  }

  static Future<void> ensureDefaultUsers() async {
    await _ensureLoaded();
    if (_cache.isNotEmpty) return;

    final now = DateTime.now();
    final parent = User(
      id: 'parent-${now.millisecondsSinceEpoch}',
      name: '家长',
      email: '',
      role: 'parent',
      avatarUrl: '',
      createdAt: now,
    );
    final child = User(
      id: 'child-${now.millisecondsSinceEpoch}',
      name: '孩子A',
      email: '',
      role: 'child',
      avatarUrl: '',
      createdAt: now,
    );

    _cache = [parent, child];
    await _persist();
  }

  static Future<User?> getUserById(String userId) async {
    await _ensureLoaded();
    try {
      return _cache.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  static Future<List<User>> getUsersByIds(List<String> ids) async {
    await _ensureLoaded();
    return _cache.where((user) => ids.contains(user.id)).toList();
  }
}