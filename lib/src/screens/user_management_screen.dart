import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [
    User(
      id: 'parent1',
      name: '爸爸',
      email: 'parent@example.com',
      role: 'parent',
      avatarUrl: '',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    User(
      id: 'child1',
      name: '小明',
      email: 'child@example.com',
      role: 'child',
      avatarUrl: '',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'child';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addUser() {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text,
        role: _selectedRole,
        avatarUrl: '',
        createdAt: DateTime.now(),
      );

      setState(() {
        _users.add(user);
      });

      // 重置表单
      _nameController.clear();
      _emailController.clear();
      _selectedRole = 'child';

      Navigator.of(context).pop();
    }
  }

  void _deleteUser(User user) {
    if (user.role == 'parent') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('不能删除家长账户')),
      );
      return;
    }

    setState(() {
      _users.removeWhere((u) => u.id == user.id);
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加用户'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入姓名';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入邮箱';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('角色'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('家长'),
                        value: 'parent',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('孩子'),
                        value: 'child',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: _addUser,
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.name[0]),
              ),
              title: Text(user.name),
              subtitle: Text('${user.email} · ${user.role == 'parent' ? '家长' : '孩子'}'),
              trailing: user.role == 'parent'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteUser(user),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}