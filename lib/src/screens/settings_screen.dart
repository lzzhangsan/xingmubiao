import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:xingmubiao/src/services/backup_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // local temp fields for UI
  ThemeStyle? _selectedStyle;
  String? _customColorHex;
  TextEditingController _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // load handled in didChangeDependencies via provider
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }
  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }


  Future<void> _resetAllPoints(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清零所有分数'),
        content: const Text('确定要将所有成员的分数清零吗？\n成员、目标、设置都会保留，仅分数记录被清除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('继续', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (first != true) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('最后确认'),
        content: const Text('这是最后确认。\n清零后所有成员的历史分数和剩余积分都会变为 0，且无法恢复。\n确定要继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定清零', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (second != true) return;

    await PointService.clear();
    await CheckinService.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所有成员分数已清零')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    _selectedStyle ??= provider.themeStyle;
    _customColorHex ??= provider.customBgColorHex;
    _imageController.text = provider.customBgImage ?? '';
    final child = provider.selectedChild;
    final childName = child?.name ?? '未选择孩子';

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      // show which child these settings apply to
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('正在为：$childName 配置', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const SizedBox.shrink(),
              const SizedBox(height: 12),
              const Text('主题设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeStyle>(
                      title: const Text('白天'),
                      value: ThemeStyle.day,
                      groupValue: _selectedStyle,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedStyle = v);
                        await provider.setThemeStyle(v);
                      },
                    ),
                    RadioListTile<ThemeStyle>(
                      title: const Text('晚上'),
                      value: ThemeStyle.night,
                      groupValue: _selectedStyle,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedStyle = v);
                        await provider.setThemeStyle(v);
                      },
                    ),
                    RadioListTile<ThemeStyle>(
                      title: const Text('简洁'),
                      value: ThemeStyle.simple,
                      groupValue: _selectedStyle,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedStyle = v);
                        await provider.setThemeStyle(v);
                      },
                    ),
                    RadioListTile<ThemeStyle>(
                      title: const Text('炫酷'),
                      value: ThemeStyle.cool,
                      groupValue: _selectedStyle,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedStyle = v);
                        await provider.setThemeStyle(v);
                      },
                    ),
                    RadioListTile<ThemeStyle>(
                      title: const Text('自定义（背景颜色/图片）'),
                      value: ThemeStyle.custom,
                      groupValue: _selectedStyle,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedStyle = v);
                        await provider.setThemeStyle(v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('自定义背景', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // pick from gallery
                              final picker = ImagePicker();
                              final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null) {
                                await provider.setCustomBgImage(file.path);
                                _imageController.text = file.path;
                                setState(() {});
                              }
                            },
                            child: const Text('从相册选择'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              // take photo
                              final picker = ImagePicker();
                              final XFile? file = await picker.pickImage(source: ImageSource.camera);
                              if (file != null) {
                                await provider.setCustomBgImage(file.path);
                                _imageController.text = file.path;
                                setState(() {});
                              }
                            },
                            child: const Text('拍照'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // open color picker dialog
                              Color current = _customColorHex != null
                                  ? _hexToColor(_customColorHex!)
                                  : (provider.customBgColorHex != null ? _hexToColor(provider.customBgColorHex!) : const Color(0xFFFFFFFF));
                              Color picked = current;
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('选择颜色（作为上层覆盖）'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: current,
                                      onColorChanged: (c) => picked = c,
                                      showLabel: true,
                                      pickerAreaHeightPercent: 0.7,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
                                    TextButton(
                                      onPressed: () async {
                                        final hex = '#${picked.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                                        await provider.setCustomBgColorHex(hex);
                                        _customColorHex = hex;
                                        // switch to custom theme
                                        await provider.setThemeStyle(ThemeStyle.custom);
                                        Navigator.of(context).pop();
                                        setState(() {});
                                      },
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('选择颜色'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              // clear custom image
                              _imageController.clear();
                              await provider.setCustomBgImage(null);
                              setState(() {});
                            },
                            child: const Text('清除图片'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('颜色不透明度：'),
                          Expanded(
                            child: Slider(
                              value: provider.customBgColorOpacity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: (provider.customBgColorOpacity * 100).round().toString() + '%',
                              onChanged: (v) async {
                                await provider.setCustomBgColorOpacity(v);
                                // ensure custom theme selected
                                if (_selectedStyle != ThemeStyle.custom) {
                                  _selectedStyle = ThemeStyle.custom;
                                  await provider.setThemeStyle(ThemeStyle.custom);
                                }
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('预览'),
                      const SizedBox(height: 8),
                      // Preview: image as bottom layer, color overlay on top with opacity
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // image layer (from local file or network)
                              if (provider.customBgImage != null && provider.customBgImage!.isNotEmpty)
                                Positioned.fill(
                                  child: provider.customBgImage!.startsWith('http')
                                      ? Image.network(provider.customBgImage!, fit: BoxFit.cover)
                                      : Image.file(File(provider.customBgImage!), fit: BoxFit.cover),
                                ),
                              // color overlay
                              if (( _customColorHex != null && _customColorHex!.isNotEmpty) || provider.customBgColorHex != null)
                                Positioned.fill(
                                  child: Container(
                                    color: (_customColorHex != null ? _hexToColor(_customColorHex!) : (provider.customBgColorHex != null ? _hexToColor(provider.customBgColorHex!) : const Color(0x00000000))).withOpacity(provider.customBgColorOpacity),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('动画强度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    RadioListTile<AnimationIntensity>(
                      title: const Text('关（关闭动画）'),
                      value: AnimationIntensity.off,
                      groupValue: provider.animationIntensity,
                      onChanged: (v) async {
                        if (v == null) return;
                        await provider.setAnimationIntensity(v);
                        setState(() {});
                      },
                    ),
                    RadioListTile<AnimationIntensity>(
                      title: const Text('低（省电）'),
                      value: AnimationIntensity.low,
                      groupValue: provider.animationIntensity,
                      onChanged: (v) async {
                        if (v == null) return;
                        await provider.setAnimationIntensity(v);
                        setState(() {});
                      },
                    ),
                    RadioListTile<AnimationIntensity>(
                      title: const Text('中（适中）'),
                      value: AnimationIntensity.medium,
                      groupValue: provider.animationIntensity,
                      onChanged: (v) async {
                        if (v == null) return;
                        await provider.setAnimationIntensity(v);
                        setState(() {});
                      },
                    ),
                    RadioListTile<AnimationIntensity>(
                      title: const Text('高（默认）'),
                      value: AnimationIntensity.high,
                      groupValue: provider.animationIntensity,
                      onChanged: (v) async {
                        if (v == null) return;
                        await provider.setAnimationIntensity(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToUserManagement,
                  child: const Text('用户管理'),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),

              const SizedBox(height: 32),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt, color: Colors.red),
                  label: const Text('全员分数清零', style: TextStyle(color: Colors.red)),
                  onPressed: () => _resetAllPoints(context),
                ),
              ),
              const SizedBox(height: 24),
              const Text('数据迁移', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final progress = ValueNotifier<String>('准备中...');
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      content: ValueListenableBuilder<String>(
                        valueListenable: progress,
                        builder: (_, msg, __) => Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Expanded(child: Text(msg)),
                          ],
                        ),
                      ),
                    ),
                  );
                  try {
                    await BackupService.exportAll(progress: progress);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
                    }
                  } finally {
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: const Text('导出全部数据'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final progress = ValueNotifier<String>('准备中...');
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      content: ValueListenableBuilder<String>(
                        valueListenable: progress,
                        builder: (_, msg, __) => Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Expanded(child: Text(msg)),
                          ],
                        ),
                      ),
                    ),
                  );
                  bool ok = false;
                  try {
                    ok = await BackupService.importAll(progress: progress);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$e')));
                    }
                  } finally {
                    if (context.mounted) Navigator.of(context).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? '导入成功，请重启应用' : '导入取消或失败')),
                    );
                  }
                },
                child: const Text('导入全部数据'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorChip(String hex, AppProvider provider) {
    final color = _hexToColor(hex);
    return GestureDetector(
      onTap: () async {
        _customColorHex = hex;
        await provider.setCustomBgColorHex(hex);
        // ensure custom style selected
        if (_selectedStyle != ThemeStyle.custom) {
          _selectedStyle = ThemeStyle.custom;
          await provider.setThemeStyle(ThemeStyle.custom);
        }
        setState(() {});
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFFFFFFFF);
    }
  }
}