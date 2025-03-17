import 'package:flutter/material.dart';
import '../services/trello_auth.dart';
import 'workspaces.dart';
import 'trello_test_screen.dart';

GlobalKey<NavigationScreenState> navigationKey = GlobalKey<NavigationScreenState>();

class NavigationScreen extends StatefulWidget {
  NavigationScreen({Key? key}) : super(key: navigationKey);

  @override
  NavigationScreenState createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> {
  final TrelloAuthService _authService = TrelloAuthService();

  int _selectedIndex = 0;

  final List<Function> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
          () => const WorkspacesScreen(),
          () => const Center(child: Text('Recherche')),
          () => const Center(child: Text('Notifications')),
          () => const TrelloDashboard(),
    ]);
  }

  void setSelectedIndex(int index) {
    if (index == 3) {
      // Remplacer par la logique réelle de déconnexion
      _authService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void setSelectedWorkspace(Map<String, dynamic> workspace) {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/FondApp.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: GestureDetector(
              onTapDown: (TapDownDetails details) {
              },
              child: Image.asset(
                'lib/assets/LogoSombre.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
          body: _pages[_selectedIndex](),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: setSelectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.black54,
            backgroundColor: Colors.white,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Workspaces',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Recherche',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bug_report),
                label: 'TEST',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Déconnexion',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
