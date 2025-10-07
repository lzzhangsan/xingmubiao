import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AvatarEditor extends StatefulWidget {
  final File imageFile;
  final double? initialScale;
  final Offset? initialOffset;

  const AvatarEditor({
    super.key,
    required this.imageFile,
    this.initialScale,
    this.initialOffset,
  });

  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  late double _scale;
  late Offset _offset;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale ?? 1.0;
    _offset = widget.initialOffset ?? Offset.zero;
    _transformationController = TransformationController();
    
    // 初始化变换矩阵
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMatrix();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑头像'),
        actions: [
          TextButton(
            onPressed: () {
              // 返回当前的缩放和偏移值
              final matrix = _transformationController.value;
              final scale = matrix.getMaxScaleOnAxis();
              final offset = Offset(matrix[4], matrix[5]);
              
              Navigator.of(context).pop({
                'scale': scale,
                'offset': offset,
              });
            },
            child: const Text('完成'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Image.file(
                  widget.imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // 控制面板
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    _scale = math.max(0.5, _scale - 0.1);
                    _updateMatrix();
                  },
                ),
                Text(
                  '${(_scale * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    _scale = math.min(3.0, _scale + 0.1);
                    _updateMatrix();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    _scale = 1.0;
                    _offset = Offset.zero;
                    _updateMatrix();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateMatrix() {
    final matrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
    _transformationController.value = matrix;
  }
}