import 'package:flutter/material.dart';
import 'src/services/firebase_service.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/goal_list_screen.dart';
import 'src/screens/checkin_screen.dart';
import 'src/screens/stats_screen.dart';
import 'src/screens/wishlist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
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
        ],
      ),
    );
  }
}
