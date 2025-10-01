import 'package:flutter/material.dart';

class GoalListScreen extends StatelessWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 添加新目标
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            // 目标分类标签
            _CategoryTabs(),
            
            // 目标列表
            _GoalList(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryTab(title: '全部', isSelected: true),
          _CategoryTab(title: '学习'),
          _CategoryTab(title: '生活'),
          _CategoryTab(title: '兴趣'),
          _CategoryTab(title: '挑战'),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _CategoryTab({required this.title, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5, // 示例数据
      itemBuilder: (context, index) {
        return _GoalListItem(
          title: '目标示例 $index',
          description: '这是目标的描述信息',
          points: 10,
          frequency: '每日',
        );
      },
    );
  }
}

class _GoalListItem extends StatelessWidget {
  final String title;
  final String description;
  final int points;
  final String frequency;

  const _GoalListItem({
    required this.title,
    required this.description,
    required this.points,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+${points}积分'),
            Text(
              frequency,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}