import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'src/providers/app_provider.dart';
import 'src/screens/checkin_screen.dart';
import 'src/screens/goal_list_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/wishlist_screen.dart';
import 'src/screens/add_reward_screen.dart';
import 'src/services/firebase_initializer.dart';
import 'src/storage/local_data_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDataStore.init();
  await FirebaseInitializer.initializeFirebase();
  await initializeDateFormatting('zh_CN');
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // derive theme data based on selected style
    ThemeData themeData;
    ThemeData darkThemeData;

    switch (provider.themeStyle) {
      case ThemeStyle.night:
        themeData = ThemeData.dark().copyWith(useMaterial3: true);
        darkThemeData = ThemeData.dark().copyWith(useMaterial3: true);
        break;
      case ThemeStyle.simple:
        themeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey, brightness: Brightness.light),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        );
        darkThemeData = ThemeData.dark().copyWith(useMaterial3: true);
        break;
      case ThemeStyle.cool:
        themeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFEDE7F6),
          useMaterial3: true,
        );
        darkThemeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF1A237E),
          useMaterial3: true,
        );
        break;
      case ThemeStyle.custom:
        final hex = provider.customBgColorHex;
        Color? bgColor;
        if (hex != null && hex.isNotEmpty) {
          try {
            bgColor = Color(int.parse(hex.replaceFirst('#', '0xff')));
          } catch (_) {
            bgColor = const Color(0xFFF5F6FA);
          }
        }
        themeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          scaffoldBackgroundColor: bgColor ?? const Color(0xFFF5F6FA),
          useMaterial3: true,
        );
        darkThemeData = ThemeData.dark().copyWith(useMaterial3: true);
        break;
      case ThemeStyle.day:
      default:
        themeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          useMaterial3: true,
        );
        darkThemeData = ThemeData.dark().copyWith(useMaterial3: true);
    }

    return MaterialApp(
      title: '每日目标',
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeData,
      darkTheme: darkThemeData,
      home: const MainScreen(),
      routes: {
        '/goals': (context) => const GoalListScreen(),
        '/wishlist': (context) => const WishlistScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    GoalListScreen(),
    CheckinScreen(),
    WishlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: '目标',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outlined),
            selectedIcon: Icon(Icons.check_circle),
            label: '打卡',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: '心愿',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      // No global FAB: each screen manages its own actions. The wishlist
      // screen already provides a top-right add button, so the bottom-right
      // FAB is removed to avoid duplication.
    );
  }
}