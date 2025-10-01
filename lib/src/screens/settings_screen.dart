import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/screens/family_screen.dart';
import 'package:xingmubiao/src/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  String _childName = '小明';
  String _parentName = '爸爸';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
      _childName = prefs.getString('childName') ?? '小明';
      _parentName = prefs.getString('parentName') ?? '爸爸';
      final hour = prefs.getInt('reminderHour') ?? 19;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('remindersEnabled', _remindersEnabled);
    await prefs.setString('childName', _childName);
    await prefs.setString('parentName', _parentName);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
    
    // 如果启用了提醒，设置每日通知
    if (_remindersEnabled) {
      await NotificationService().scheduleDailyNotification(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        title: '目标提醒',
        body: '该完成今天的任务了！',
      );
    } else {
      // 如果关闭了提醒，取消所有通知
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      _saveSettings();
    }
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToFamilyManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '账户设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _childName,
                        decoration: const InputDecoration(
                          labelText: '孩子姓名',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _childName = value;
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _parentName,
                        decoration: const InputDecoration(
                          labelText: '家长姓名',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _parentName = value;
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToUserManagement,
                          child: const Text('用户管理'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _navigateToFamilyManagement,
                          child: const Text('家庭管理'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '通知设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('启用通知'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('启用提醒'),
                        value: _remindersEnabled,
                        onChanged: (value) {
                          setState(() {
                            _remindersEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('提醒时间'),
                        subtitle: Text('${_reminderTime.hour}:${_reminderTime.minute.toString().padLeft(2, '0')}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectReminderTime,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '关于',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('应用版本'),
                        subtitle: Text('1.0.0'),
                      ),
                      const Divider(),
                      const ListTile(
                        title: Text('检查更新'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      const Divider(),
                      const ListTile(
                        title: Text('用户协议'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      const Divider(),
                      const ListTile(
                        title: Text('隐私政策'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}