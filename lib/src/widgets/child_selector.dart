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
            const Icon(Icons.family_restroom_outlined),
            const SizedBox(width: 4),
            Text(selected?.name ?? '选择孩子'),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
