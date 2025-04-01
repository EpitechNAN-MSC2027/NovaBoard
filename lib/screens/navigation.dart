import 'package:flutter/material.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'workspaces.dart';
import 'search.dart';
import 'notifications.dart';

GlobalKey<NavigationScreenState> navigationKey = GlobalKey<NavigationScreenState>();

class NavigationScreen extends StatefulWidget {
  final TrelloService? trelloService;

  NavigationScreen({Key? key, this.trelloService}) : super(key: navigationKey);

  @override
  NavigationScreenState createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> {

  TrelloService? _trelloService;
  bool _hasUnreadNotifications = false;

  int selectedIndex = 0;

  final List<Function> _pages = [];

  static var bottomWidgetKey = GlobalKey<State<BottomNavigationBar>>();

  @override
  void initState() {
    super.initState();
    _initTrelloService().then((_) => _checkUnreadNotifications());
    _pages.addAll([
          () => const WorkspacesScreen(),
          () => const SearchScreen(),
          () => const NotificationsScreen(),
          () => const SizedBox.shrink(),
    ]);
  }

  Future<void> _initTrelloService() async {
    if (widget.trelloService != null) {
      _trelloService = widget.trelloService!;
      return;
    }
    final authService = TrelloAuthService();
    final token = await authService.getStoredAccessToken() ?? '';
    if (token.isNotEmpty) {
      _trelloService = TrelloService(
        apiKey: const String.fromEnvironment('TRELLO_API_KEY'),
        token: token,
      );
    }
  }

  Future<void> logout() async {
    await TrelloAuthService().logout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _checkUnreadNotifications() async {
    if (_trelloService == null) return;
    final unread = await _trelloService!.hasUnreadNotifications();
    setState(() {
      _hasUnreadNotifications = unread;
    });
  }

  void setSelectedIndex(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 2) {
        _hasUnreadNotifications = false;
      }
    });
  }

  void setSelectedWorkspace(Map<String, dynamic> workspace) {
    setState(() {
      selectedIndex = 0;
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
          body: _pages[selectedIndex](),
          bottomNavigationBar: BottomNavigationBar(
            key: bottomWidgetKey,
            currentIndex: selectedIndex,
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
    )],
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
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Workspaces',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Recherche',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (_hasUnreadNotifications)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(
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
