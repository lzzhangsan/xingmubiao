import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/screens/family_screen.dart';

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
  void _navigateToUserManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToFamilyManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    _selectedStyle ??= provider.themeStyle;
    _customColorHex ??= provider.customBgColorHex;
    _imageController.text = provider.customBgImage ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      const Text('选择背景颜色（示例）'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _colorChip('#FFFFFF', provider),
                          const SizedBox(width: 8),
                          _colorChip('#F5F6FA', provider),
                          const SizedBox(width: 8),
                          _colorChip('#FFEFD5', provider),
                          const SizedBox(width: 8),
                          _colorChip('#E8F5E9', provider),
                          const SizedBox(width: 8),
                          _colorChip('#E3F2FD', provider),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('或输入图片 URL（示例：https://.../bg.jpg）'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _imageController,
                        decoration: const InputDecoration(
                          labelText: '背景图片 URL 或本地路径',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) async {
                          await provider.setCustomBgImage(value.isEmpty ? null : value);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              // clear custom image
                              _imageController.clear();
                              await provider.setCustomBgImage(null);
                              setState(() {});
                            },
                            child: const Text('清除图片'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final value = _imageController.text.trim();
                              await provider.setCustomBgImage(value.isEmpty ? null : value);
                              setState(() {});
                            },
                            child: const Text('保存图片'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('预览'),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _customColorHex != null ? _hexToColor(_customColorHex!) : (provider.customBgColorHex != null ? _hexToColor(provider.customBgColorHex!) : null),
                          image: provider.customBgImage != null && provider.customBgImage!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(provider.customBgImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToUserManagement,
                  child: const Text('用户管理'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToFamilyManagement,
                  child: const Text('家庭管理'),
                ),
              ),
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