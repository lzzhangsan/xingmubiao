import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/services/user_service.dart';
// 添加头像编辑器的导入
import 'package:xingmubiao/src/widgets/avatar_editor.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  XFile? _pickedAvatar;
  String _selectedRole = 'child';
  // 添加头像编辑相关的变量
  double? _avatarScale;
  Offset? _avatarOffset;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: '',
      role: _selectedRole,
      avatarUrl: _pickedAvatar?.path ?? '',
      createdAt: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    final navigator = Navigator.of(context);
    await provider.addUser(user);

    if (!mounted) return;
    _nameController.clear();
    _pickedAvatar = null;
    _selectedRole = 'child';
    navigator.pop();
  }

  // 修改_pickAvatar方法以支持头像编辑
  void _showPickAvatarSheet({required void Function(XFile) onPicked}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () async {
                final image = await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) {
                  // 拍照后直接选择，不进行编辑
                  onPicked(image);
                }
                if (mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  // 从相册选择后可以进行编辑
                  final result = await _editAvatar(context, image);
                  if (result != null && mounted) {
                    onPicked(result);
                  }
                }
                if (mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 添加头像编辑方法
  Future<XFile?> _editAvatar(BuildContext context, XFile imageFile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AvatarEditor(
          imageFile: File(imageFile.path),
          initialScale: _avatarScale,
          initialOffset: _avatarOffset,
        ),
      ),
    );

    if (result != null) {
      // 保存编辑参数，以便下次使用
      _avatarScale = result['scale'] as double?;
      _avatarOffset = result['offset'] as Offset?;
      return imageFile;
    }
    return null;
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
                GestureDetector(
                  onTap: () => _showPickAvatarSheet(onPicked: (img) => setState(() => _pickedAvatar = img)),
                  child: CircleAvatar(
                    // 将半径从36增加到72（双倍大小）
                    radius: 72,
                    backgroundImage: _pickedAvatar != null ? FileImage(File(_pickedAvatar!.path)) : null,
                    child: _pickedAvatar == null
                        // 将图标大小从28增加到56（双倍大小）
                        ? const Icon(Icons.camera_alt, size: 56)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
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

  void _showEditUserDialog(BuildContext context, User user) {
    final editFormKey = GlobalKey<FormState>();
    final editNameController = TextEditingController(text: user.name);
    String editRole = user.role;
    XFile? editPicked;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('编辑成员'),
              content: Form(
                key: editFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showPickAvatarSheet(onPicked: (img) {
                        editPicked = img;
                        setStateDialog(() {});
                      }),
                      child: CircleAvatar(
                        // 将半径从36增加到72（双倍大小）
                        radius: 72,
                        backgroundImage: editPicked != null
                            ? FileImage(File(editPicked!.path))
                            : (user.avatarUrl.isNotEmpty ? FileImage(File(user.avatarUrl)) : null),
                        child: (editPicked == null && user.avatarUrl.isEmpty)
                            // 将图标大小从28增加到56（双倍大小）
                            ? const Icon(Icons.camera_alt, size: 56)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editNameController,
                      decoration: const InputDecoration(
                        labelText: '姓名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? '请输入姓名' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: editRole,
                      decoration: const InputDecoration(
                        labelText: '身份',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'child', child: Text('孩子')),
                        DropdownMenuItem(value: 'parent', child: Text('家长')),
                      ],
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => editRole = value);
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
                  onPressed: () async {
                    if (!(editFormKey.currentState?.validate() ?? false)) return;
                    final updated = User(
                      id: user.id,
                      name: editNameController.text.trim(),
                      email: user.email,
                      role: editRole,
                      avatarUrl: editPicked?.path ?? user.avatarUrl,
                      createdAt: user.createdAt,
                    );
                    await UserService.updateUser(updated);
                    await context.read<AppProvider>().refreshUsers();
                    if (mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
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
                          // 将半径从默认值增加到双倍大小
                          radius: 24,
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? FileImage(File(user.avatarUrl))
                              : null,
                          child: user.avatarUrl.isEmpty
                              ? Text(user.name.isNotEmpty ? user.name[0] : '?')
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(isChild ? '孩子' : '家长'),
                        onTap: () => _showEditUserDialog(context, user),
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