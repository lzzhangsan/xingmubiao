import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/services/reward_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Reward> _rewards = [];
  int _userPoints = 1250; // 模拟用户积分
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rewards = await RewardService.getRewards();
      final points = await PointService.getTotalPoints('child1');

      setState(() {
        _rewards = rewards;
        _userPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  void _redeemReward(Reward reward) {
    if (_userPoints >= reward.pointsRequired) {
      setState(() {
        _userPoints -= reward.pointsRequired;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功兑换：${reward.title}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('积分不足，无法兑换'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddReward() {
    Navigator.pushNamed(context, '/add-reward').then((value) {
      if (value == true) {
        _loadData(); // 如果添加了新心愿，重新加载数据
      }
    });
  }

  void _editReward(Reward reward) {
    // 这里应该导航到编辑心愿页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能待实现')),
    );
  }

  void _deleteReward(Reward reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除心愿"${reward.title}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await RewardService.deleteReward(reward.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('删除成功')),
                    );
                    _loadData(); // 重新加载数据
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('删除失败: $e')),
                    );
                  }
                }
              },
              child: const Text('删除'),
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
        title: const Text('心愿库'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('积分: $_userPoints'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '如何使用心愿库？',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '完成目标可以获得积分，积分可以兑换心愿库中的奖励。',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '当前积分: $_userPoints',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rewards.length,
                    itemBuilder: (context, index) {
                      final reward = _rewards[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    reward.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      if (value == 'edit') {
                                        _editReward(reward);
                                      } else if (value == 'delete') {
                                        _deleteReward(reward);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('编辑'),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('删除'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(reward.description),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${reward.pointsRequired}积分',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _redeemReward(reward),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _userPoints >= reward.pointsRequired
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    child: Text(
                                      _userPoints >= reward.pointsRequired
                                          ? '兑换'
                                          : '积分不足',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddReward,
        child: const Icon(Icons.add),
      ),
    );
  }
}