import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'src/providers/app_provider.dart';
import 'src/screens/checkin_screen.dart';
import 'src/screens/goal_list_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/wishlist_screen.dart';
import 'src/screens/add_reward_screen.dart';
import 'src/services/firebase_initializer.dart';
import 'src/storage/local_data_store.dart';
import 'src/widgets/cool_background.dart';
import 'src/navigation/route_observer.dart';

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
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
          useMaterial3: true,
        );
        darkThemeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
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
        // Use transparent scaffold/appBar so the custom background (painted in
        // MaterialApp.builder) is visible underneath the Scaffold.
        themeData = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
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
  navigatorObservers: [routeObserver],
  builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();

        // If the custom theme is selected, render custom background layers:
        // - bottom: image (from gallery/camera path or network)
        // - top: color overlay with adjustable opacity
        if (provider.themeStyle == ThemeStyle.custom) {
          Widget bg = const SizedBox.shrink();
          if (provider.customBgImage != null && provider.customBgImage!.isNotEmpty) {
            final path = provider.customBgImage!;
            if (path.startsWith('http')) {
              bg = Positioned.fill(child: Image.network(path, fit: BoxFit.cover));
            } else {
              bg = Positioned.fill(child: Image.file(File(path), fit: BoxFit.cover));
            }
          }

          Widget colorOverlay = const SizedBox.shrink();
          if (provider.customBgColorHex != null && provider.customBgColorHex!.isNotEmpty) {
            try {
              final color = Color(int.parse(provider.customBgColorHex!.replaceFirst('#', '0xff')));
              colorOverlay = Positioned.fill(child: Container(color: color.withOpacity(provider.customBgColorOpacity)));
            } catch (_) {
              // ignore parse errors
            }
          }

          content = Stack(children: [
            if (bg is! SizedBox) bg,
            if (colorOverlay is! SizedBox) colorOverlay,
            Positioned.fill(child: content),
          ]);
        } else {
          // If a custom background image is set (non-custom theme), paint it behind the content
          if (provider.customBgImage != null && provider.customBgImage!.isNotEmpty) {
            final path = provider.customBgImage!;
            final ImageProvider backgroundImage = path.startsWith('http') ? NetworkImage(path) : FileImage(File(path));
            content = Stack(
              children: [
                Positioned.fill(
                  child: Image(
                    image: backgroundImage,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(child: content),
              ],
            );
          }

          // If the cool theme is selected, wrap the entire app content in the animated background
          if (provider.themeStyle == ThemeStyle.cool) {
            content = AnimatedCoolBackground(child: content, dimContent: true);
          }
        }

        return content;
      },
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
    final provider = Provider.of<AppProvider>(context);

    Widget bodyContent = _screens[_selectedIndex];

    return Scaffold(
      body: bodyContent,
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