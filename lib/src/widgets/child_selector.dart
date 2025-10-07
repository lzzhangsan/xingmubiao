import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';

class ChildSelector extends StatelessWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final children = provider.children;
    final selected = provider.selectedChild;

    if (!provider.isInitialized) {
      return const SizedBox.shrink();
    }

    if (children.isEmpty) {
      return IconButton(
        tooltip: '添加孩子',
        icon: const Icon(Icons.person_add_alt),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const UserManagementScreen(),
            ),
          );
        },
      );
    }

    return PopupMenuButton<String>(
      tooltip: '切换孩子',
      initialValue: selected?.id,
      onSelected: (value) async {
        final navigator = Navigator.of(context);
        final appProvider = context.read<AppProvider>();
        if (value == '_manage') {
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => const UserManagementScreen(),
            ),
          );
          await appProvider.refreshUsers();
          return;
        }
        await appProvider.setSelectedChildId(value);
      },
      itemBuilder: (context) => [
        for (final child in children)
          PopupMenuItem(
            value: child.id,
            child: Row(
              children: [
                if (child.id == selected?.id)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                CircleAvatar(
                  // 将半径从12增加到24（双倍大小）
                  radius: 24,
                  backgroundImage: child.avatarUrl.isNotEmpty
                      ? FileImage(File(child.avatarUrl))
                      : null,
                  child: child.avatarUrl.isEmpty
                      ? Text(child.name.isNotEmpty ? child.name[0] : '?')
                      : null,
                ),
                const SizedBox(width: 8),
                Text(child.name),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: '_manage',
          child: Row(
            children: [
              Icon(Icons.manage_accounts, size: 18),
              SizedBox(width: 8),
              Text('管理成员'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              // 将半径从14增加到28（双倍大小）
              radius: 28,
              backgroundImage: (selected?.avatarUrl.isNotEmpty ?? false)
                  ? FileImage(File(selected!.avatarUrl))
                  : null,
              child: (selected?.avatarUrl.isEmpty ?? true)
                  ? Text((selected?.name.isNotEmpty ?? false) ? selected!.name[0] : '?')
                  : null,
            ),
            const SizedBox(width: 6),
            Text(selected?.name ?? '选择孩子'),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}