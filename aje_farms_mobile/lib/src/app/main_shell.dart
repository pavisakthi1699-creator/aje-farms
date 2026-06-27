part of '../app.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    CoursesScreen(),
    AiChatScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Nyumbani'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'Mafunzo'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined), label: 'Uliza AI'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Jamii'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Akaunti'),
        ],
      ),
    );
  }
}
