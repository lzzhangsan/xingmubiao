import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/firebase_service.dart';
import 'src/providers/app_provider.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/goal_list_screen.dart';
import 'src/screens/checkin_screen.dart';
import 'src/screens/stats_screen.dart';
import 'src/screens/wishlist_screen.dart';
import 'src/screens/achievements_screen.dart';
import 'src/screens/add_goal_screen.dart';
import 'src/screens/add_reward_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/services/firebase_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 使用新的Firebase初始化器，即使失败也不会中断应用启动
  await FirebaseInitializer.initializeFirebase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '星目标',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      routes: {
        '/goals': (context) => const GoalListScreen(),
        '/add-goal': (context) => const AddGoalScreen(),
        '/add-reward': (context) => const AddRewardScreen(),
        '/wishlist': (context) => const WishlistScreen(),
        '/achievements': (context) => const AchievementsScreen(),
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
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GoalListScreen(),
    const CheckinScreen(),
    const StatsScreen(),
    const WishlistScreen(),
    const AchievementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: '目标',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: '打卡',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: '心愿',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '成就',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 4
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-reward');
              },
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}