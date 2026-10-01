import 'package:flutter/material.dart';
import 'game_state.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WalkTripApp());
}

class WalkTripApp extends StatelessWidget {
  const WalkTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walk Trip',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey, // 알림 카드용
      // 와이어프레임 단계라 회색 톤으로 통일
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

/// 하단 탭(메인, 도감)을 가진 기본 뼈대
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GameState game = GameState();
  int tab = 0;

  @override
  void dispose() {
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          MainScreen(game: game),
          ProfileScreen(game: game),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_walk), label: 'Walk'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}