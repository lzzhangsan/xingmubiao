import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/add_reward_screen.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';
import 'package:xingmubiao/src/widgets/child_selector.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Reward> _rewards = [];
  int _userPoints = 0;
  bool _isLoading = true;
  bool _isFetching = false;

  AppProvider? _provider;
  String? _currentChildId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context);
    if (_provider != provider) {
      _provider?.removeListener(_handleProviderChanged);
      _provider = provider;
      provider.addListener(_handleProviderChanged);
      _handleProviderChanged();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderChanged);
    super.dispose();
  }

  void _handleProviderChanged() {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final newChildId = provider.selectedChild?.id;
    if (newChildId != _currentChildId) {
      _currentChildId = newChildId;
      _loadData();
    }
  }

  Future<void> _loadData({bool showLoader = true}) async {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final child = provider.selectedChild;
    if (child == null) {
      setState(() {
        _rewards = [];
        _userPoints = 0;
        _isLoading = false;
      });
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final rewards = await RewardService.getRewards();
      final points = await PointService.getTotalPoints(child.id);
      if (!mounted) return;
      setState(() {
        _rewards = rewards;
        _userPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载心愿数据失败: $e')),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    final child = _provider?.selectedChild;
    if (child == null) return;

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
        userId: child.id,
        amount: reward.pointsRequired,
        reason: '兑换奖励：${reward.title}',
        type: 'spent',
        relatedId: reward.id,
        createdAt: DateTime.now(),
      );
      await PointService.addPoint(record);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('兑换成功，已扣除 ${reward.pointsRequired} 积分')),
      );

      await _loadData(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('记录积分失败: $e')),
      );
    }
  }

  Future<void> _openRewardEditor({Reward? reward}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddRewardScreen(initialReward: reward)),
    );
    if (result == true) {
      await _loadData(showLoader: false);
    }
  }

  void _deleteReward(Reward reward) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除心愿'),
        content: Text('确定要删除“${reward.title}”吗？'),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              navigator.pop();
              try {
                await RewardService.deleteReward(reward.id);
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('删除成功')));
                await _loadData(showLoader: false);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('还没有孩子成员，无法管理心愿'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
              child: const Text('前往成员管理'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedChild = provider.selectedChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('心愿奖励'),
        actions: [
          const ChildSelector(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增奖励',
            onPressed: () => _openRewardEditor(),
          ),
        ],
      ),
      body: !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : selectedChild == null
              ? _buildNoChildView()
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _loadData(showLoader: false),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedChild.name} 当前可用积分',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$_userPoints 分',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const Icon(Icons.savings_outlined,
                                          size: 32, color: Colors.blue),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('完成目标后将自动累积积分，可在此兑换心愿奖励。'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_rewards.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('还没有设置心愿，点击右上角添加吧。')),
                            )
                          else
                            ..._rewards.map(
                              (reward) => Card(
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
                                                _openRewardEditor(reward: reward);
                                              } else if (value == 'delete') {
                                                _deleteReward(reward);
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
                                            onPressed: () => _redeemReward(reward),
                                            child: Text(
                                              _userPoints >= reward.pointsRequired
                                                  ? '立即兑换'
                                                  : '积分不足',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
