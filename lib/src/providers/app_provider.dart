import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/user.dart';

class AppProvider with ChangeNotifier {
  // 当前用户
  User? _currentUser;
  
  // 当前选中的孩子
  User? _selectedChild;
  
  // 用户列表
  List<User> _users = [];
  
  // 积分余额
  int _pointsBalance = 0;
  
  // 通知设置
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  
  // 获取当前用户
  User? get currentUser => _currentUser;
  
  // 获取当前选中的孩子
  User? get selectedChild => _selectedChild;
  
  // 获取用户列表
  List<User> get users => _users;
  
  // 获取积分余额
  int get pointsBalance => _pointsBalance;
  
  // 获取通知设置
  bool get notificationsEnabled => _notificationsEnabled;
  bool get remindersEnabled => _remindersEnabled;
  
  // 设置当前用户
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // 设置选中的孩子
  void setSelectedChild(User child) {
    _selectedChild = child;
    notifyListeners();
  }
  
  // 设置用户列表
  void setUsers(List<User> users) {
    _users = users;
    notifyListeners();
  }
  
  // 更新积分余额
  void updatePointsBalance(int balance) {
    _pointsBalance = balance;
    notifyListeners();
  }
  
  // 更新通知设置
  void updateNotificationSettings({
    bool? notificationsEnabled,
    bool? remindersEnabled,
  }) {
    if (notificationsEnabled != null) {
      _notificationsEnabled = notificationsEnabled;
    }
    if (remindersEnabled != null) {
      _remindersEnabled = remindersEnabled;
    }
    notifyListeners();
  }
  
  // 添加用户
  void addUser(User user) {
    _users.add(user);
    notifyListeners();
  }
  
  // 删除用户
  void removeUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
    notifyListeners();
  }
}