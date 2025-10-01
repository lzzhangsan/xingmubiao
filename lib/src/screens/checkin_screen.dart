import 'package:flutter/material.dart';

class CheckinScreen extends StatelessWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日打卡'),
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            // 日期选择
            _DateSelector(),
            
            // 打卡目标列表
            _CheckinGoalList(),
            
            // 打卡统计
            _CheckinStats(),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 前一天
            },
          ),
          const Text(
            '2025年10月1日',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              // 后一天
            },
          ),
        ],
      ),
    );
  }
}

class _CheckinGoalList extends StatelessWidget {
  const _CheckinGoalList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // 示例数据
      itemBuilder: (context, index) {
        return _CheckinGoalItem(
          title: '目标示例 $index',
          points: 10,
        );
      },
    );
  }
}

class _CheckinGoalItem extends StatefulWidget {
  final String title;
  final int points;

  const _CheckinGoalItem({
    required this.title,
    required this.points,
  });

  @override
  State<_CheckinGoalItem> createState() => _CheckinGoalItemState();
}

class _CheckinGoalItemState extends State<_CheckinGoalItem> {
  int _selectedScore = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('+${widget.points}积分'),
            const SizedBox(height: 16),
            
            // 评分组件
            const Text('请评分：'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedScore ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedScore = index + 1;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 评论输入
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: '添加评论...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // 图片上传
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // 上传图片
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照打卡'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectedScore > 0 ? () {
                    // 提交打卡
                  } : null,
                  child: const Text('提交'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinStats extends StatelessWidget {
  const _CheckinStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(title: '已完成', value: '2'),
              _StatCard(title: '总积分', value: '25'),
              _StatCard(title: '平均分', value: '4.5'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
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