import 'package:flutter/material.dart';
import '../services/trello_auth.dart';
import 'workspaces.dart';
import 'notifications.dart';

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
          () => const NotificationsScreen(),
          () => const SizedBox.shrink(),
    ]);
  }

  Future<void> logout() async {
    await TrelloAuthService().logout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
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
            onTap: (index) {
              if (index == 3) {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await logout();
                          },
                          child: const Text('Déconnexion'),
    ),
                      ],
                    );
                  },
                );
              } else {
                setSelectedIndex(index);
              }
            },
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
