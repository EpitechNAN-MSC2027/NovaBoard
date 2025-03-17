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
                _showProfileMenu(context, details.globalPosition);
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
            ],
          ),
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'profile',
          child: Text('Profil'),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Text('Paramètres'),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Déconnexion'),
        ),
      ],
    ).then((value) {
      if (value == 'profile') {
        debugPrint('Accès au profil utilisateur...');
      } else if (value == 'settings') {
        debugPrint('Accès aux paramètres...');
      } else if (value == 'logout') {
        _authService.logout();
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }
}