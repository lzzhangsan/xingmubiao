import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/achievement.dart';
import 'package:xingmubiao/src/services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: 全部, 1: 已解锁, 2: 未解锁

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Achievement> achievements;
      if (_selectedTab == 0) {
        achievements = await AchievementService.getAchievements();
      } else if (_selectedTab == 1) {
        achievements = await AchievementService.getUnlockedAchievements();
      } else {
        achievements = await AchievementService.getLockedAchievements();
      }

      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载成就失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就系统'),
      ),
      body: Column(
        children: [
          // 标签页
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('全部'),
                    selected: _selectedTab == 0,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = selected ? 0 : _selectedTab;
                      });
                      _loadAchievements();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('已解锁'),
                    selected: _selectedTab == 1,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = selected ? 1 : _selectedTab;
                      });
                      _loadAchievements();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('未解锁'),
                    selected: _selectedTab == 2,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = selected ? 2 : _selectedTab;
                      });
                      _loadAchievements();
                    },
                  ),
                ),
              ],
            ),
          ),
          // 成就列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _achievements.isEmpty
                    ? const Center(child: Text('暂无成就'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _achievements.length,
                        itemBuilder: (context, index) {
                          return _AchievementItem(
                            achievement: _achievements[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final Achievement achievement;

  const _AchievementItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 成就图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked ? Colors.amber : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.isUnlocked ? Icons.star : Icons.lock_outline,
                color: achievement.isUnlocked ? Colors.white : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // 成就信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: achievement.isUnlocked ? Colors.grey[700] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${achievement.pointsRequired >= 0 ? '+' : ''}${achievement.pointsRequired}积分',
                    style: TextStyle(
                      color: achievement.isUnlocked ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (achievement.isUnlocked && achievement.unlockedAt != null)
                    Text(
                      '解锁于 ${_formatDate(achievement.unlockedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
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