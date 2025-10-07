import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
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

  Future<void> _addUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
      avatarUrl: '',
      createdAt: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    final navigator = Navigator.of(context);
    await provider.addUser(user);

    if (!mounted) return;
    _nameController.clear();
    _emailController.clear();
    _selectedRole = 'child';
    navigator.pop();
  }

  Future<void> _deleteUser(BuildContext context, User user) async {
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (user.role == 'parent') {
      messenger.showSnackBar(const SnackBar(content: Text('不能删除家长账户')));
      return;
    }

    final children = provider.children;
    if (user.role == 'child' && children.length <= 1) {
      messenger.showSnackBar(const SnackBar(content: Text('至少保留一名孩子成员')));
      return;
    }

    await provider.removeUser(user.id);
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('添加成员'),
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
                    if (value == null || value.trim().isEmpty) {
                      return '请输入姓名';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱（可选）',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: '身份',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'child', child: Text('孩子')),
                    DropdownMenuItem(value: 'parent', child: Text('家长')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => _addUser(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成员管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加成员',
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('暂无成员，点击右上角添加。'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isChild = user.role == 'child';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                        ),
                        title: Text(user.name),
                        subtitle: Text(isChild ? '孩子' : '家长'),
                        trailing: isChild
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteUser(context, user),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
