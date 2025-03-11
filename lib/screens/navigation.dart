import 'package:flutter/material.dart';
import 'carte.dart';
import 'workspaces.dart';
import 'tableau.dart';
import 'listes.dart';

GlobalKey<NavigationScreenState> navigationKey = GlobalKey<NavigationScreenState>();

class NavigationScreen extends StatefulWidget {
  NavigationScreen({Key? key}) : super(key: navigationKey);

  @override
  NavigationScreenState createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  Map<String, dynamic>? _selectedWorkspace;
  Map<String, dynamic>? _selectedTableau;


  final List<Function> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
          () => const  WorkspacesScreen(),
          () => TableauScreen(
        workspace: _selectedWorkspace ?? {'nom': 'Aucun workspace sélectionné', 'tableaux': []},
      ),
          () => ListesScreen(
            workspace: _selectedWorkspace ?? {'nom': 'Aucun workspace sélectionné', 'tableaux': []},
            tableau: _selectedTableau ?? {'nom': 'Aucun tableau sélectionné', 'tableaux': []},
          ),

          () => const CarteScreen(),
          () => const Center(child: Text('Recherche')),
          () => const Center(child: Text('Notifications')),
    ]);
  }

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void setSelectedWorkspace(Map<String, dynamic> workspace) {
    setState(() {
      _selectedWorkspace = workspace;
      _selectedIndex = 1;
    });
  }

  void setSelectedTableau(Map<String, dynamic> workspace, Map<String, dynamic> tableau) {
    setState(() {
      _selectedWorkspace = workspace;
      _selectedIndex = 2;
    });
  }

  void setSelectedListe(Map<String, dynamic> tableau, Map<String, dynamic> liste) {
    setState(() {
      _selectedIndex = 3;
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
                icon: Icon(Icons.assignment),
                label: 'Tableaux',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_list),
                label: 'Listes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description),
                label: 'Cartes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Recherche',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Notifications',
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
      if (value == 'logout') {
        debugPrint('Déconnexion en cours...');
      } else if (value == 'profile') {
        debugPrint('Accès au profil utilisateur...');
      } else if (value == 'settings') {
        debugPrint('Accès aux paramètres...');
      }
    });
  }
}