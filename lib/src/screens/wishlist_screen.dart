import 'package:flutter/material.dart';
import 'package:xingmubiao/src/services/reward_service.dart';
import 'package:xingmubiao/src/models/reward.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Reward> _rewards = [];
  int _userPoints = 1250; // 模拟用户积分

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final rewards = await RewardService.getRewards();
    setState(() {
      _rewards = rewards;
    });
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
      body: Column(
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
                        Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
        onPressed: () {
          // 添加新心愿
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加心愿功能待实现')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}