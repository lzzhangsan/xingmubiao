import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/screens/add_reward_screen.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Reward> _rewards = [];
  int _userPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final rewards = await RewardService.getRewards();
      final points = await PointService.getTotalPoints('child1');
      setState(() {
        _rewards = rewards;
        _userPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败：$e')),
      );
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    if (_userPoints < reward.pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('积分不足，暂时无法兑换'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final record = Point(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'child1',
        amount: reward.pointsRequired,
        reason: '兑换奖励：${reward.title}',
        type: 'spent',
        relatedId: reward.id,
        createdAt: DateTime.now(),
      );
      await PointService.addPoint(record);

      setState(() {
        _userPoints -= reward.pointsRequired;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('兑换成功！快去兑现“${reward.title}”的奖励吧。'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('记录积分失败：$e')),
      );
    }
  }

  Future<void> _openRewardEditor({Reward? reward}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRewardScreen(initialReward: reward),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  void _deleteReward(Reward reward) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除心愿“${reward.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await RewardService.deleteReward(reward.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
                await _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败：$e')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心愿与奖励'),
        actions: [
          IconButton(
            tooltip: '新增奖励',
            icon: const Icon(Icons.add),
            onPressed: () => _openRewardEditor(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PointsSummary(points: _userPoints),
                  const SizedBox(height: 16),
                  if (_rewards.isEmpty)
                    const _EmptyRewardPlaceholder()
                  else
                    ..._rewards.map(
                      (reward) => _RewardCard(
                        reward: reward,
                        canRedeem: _userPoints >= reward.pointsRequired,
                        onRedeem: () => _redeemReward(reward),
                        onEdit: () => _openRewardEditor(reward: reward),
                        onDelete: () => _deleteReward(reward),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRewardEditor(),
        icon: const Icon(Icons.add),
        label: const Text('添加心愿'),
      ),
    );
  }
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前积分',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$points 分',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Icon(Icons.savings_outlined, size: 32, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            const Text('孩子完成目标后将获得积分，可在这里兑换心愿奖励。'),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.canRedeem,
    required this.onRedeem,
    required this.onEdit,
    required this.onDelete,
  });

  final Reward reward;
  final bool canRedeem;
  final VoidCallback onRedeem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                      const SizedBox(height: 6),
                      Text(reward.description),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reward.pointsRequired} 分',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                FilledButton(
                  onPressed: canRedeem ? onRedeem : null,
                  child: Text(canRedeem ? '立即兑换' : '积分不足'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRewardPlaceholder extends StatelessWidget {
  const _EmptyRewardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              '暂未设置任何心愿',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '把孩子的期望记录在这里，完成目标就能兑换，激励效果翻倍。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
