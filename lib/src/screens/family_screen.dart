import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/family.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/services/family_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<Family> _families = [];
  List<User> _familyMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final families = await FamilyService.getFamilies();
      if (families.isNotEmpty) {
        final members = await FamilyService.getFamilyMembers(families[0].id);
        setState(() {
          _families = families;
          _familyMembers = members;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载家庭信息失败: $e')),
        );
      }
    }
  }

  Future<void> _createFamily() async {
    final familyName = await _showCreateFamilyDialog();
    if (familyName != null && familyName.isNotEmpty) {
      try {
        final family = Family(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: familyName,
          ownerId: 'parent1', // 实际应用中应该是当前用户ID
          memberIds: ['parent1'], // 实际应用中应该是当前用户ID
          createdAt: DateTime.now(),
          invitationCode: _generateInvitationCode(),
        );

        await FamilyService.createFamily(family);
        await _loadFamilies();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('家庭创建成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建家庭失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _joinFamily() async {
    final invitationCode = await _showJoinFamilyDialog();
    if (invitationCode != null && invitationCode.isNotEmpty) {
      try {
        final family = await FamilyService.getFamilyByInvitationCode(invitationCode);
        if (family != null) {
          await FamilyService.addMemberToFamily(family.id, 'parent1'); // 实际应用中应该是当前用户ID
          await _loadFamilies();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('加入家庭成功')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('邀请码无效')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加入家庭失败: $e')),
          );
        }
      }
    }
  }

  Future<String?> _showCreateFamilyDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('创建家庭'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入家庭名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showJoinFamilyDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加入家庭'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入邀请码'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('加入'),
            ),
          ],
        );
      },
    );
  }

  String _generateInvitationCode() {
    // 生成随机邀请码
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = StringBuffer();
    for (int i = 0; i < 8; i++) {
      random.write(chars[DateTime.now().millisecondsSinceEpoch % chars.length]);
    }
    return random.toString();
  }

  void _showInvitationCode(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('家庭邀请码'),
          content: SelectableText(
            code,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 复制到剪贴板
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
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
        title: const Text('家庭管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _families.isEmpty
              ? _buildEmptyState()
              : _buildFamilyView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有家庭',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createFamily,
              child: const Text('创建家庭'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _joinFamily,
              child: const Text('加入家庭'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyView() {
    final family = _families[0]; // 假设只有一个家庭
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          family.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showInvitationCode(family.invitationCode ?? ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('创建于: ${_formatDate(family.createdAt)}'),
                    const SizedBox(height: 8),
                    Text('邀请码: ${family.invitationCode}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '家庭成员',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _familyMembers.length,
              itemBuilder: (context, index) {
                final member = _familyMembers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      // 将默认大小调整为双倍
                      radius: 24,
                      child: Text(member.name[0]),
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.role == 'parent' ? '家长' : '孩子'),
                    trailing: member.id == family.ownerId
                        ? const Icon(Icons.star, color: Colors.amber)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
