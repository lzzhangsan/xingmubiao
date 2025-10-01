import 'package:flutter/material.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    '全部',
    '学习',
    '生活',
    '兴趣',
    '挑战',
  ];

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('添加新目标功能待实现')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 目标分类标签
            _CategoryTabs(
              categories: _categories,
              selectedIndex: _selectedCategoryIndex,
              onCategorySelected: (index) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
            ),
            
            // 目标列表
            const _GoalList(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.asMap().entries.map((entry) => _CategoryTab(
                title: entry.value,
                isSelected: entry.key == selectedIndex,
                onTap: () => onCategorySelected(entry.key),
              )),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function() onTap;

  const _CategoryTab({
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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