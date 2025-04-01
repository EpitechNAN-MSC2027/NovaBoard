import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'detail_carte.dart';
import 'workspace_details.dart';
import 'listes.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreen createState() => _SearchScreen();
}

class _SearchScreen extends State<SearchScreen> {
  TrelloService? _trelloService;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  bool _showCards = true;
  bool _showBoards = true;
  bool _showWorkspaces = true;
  bool _showMembers = true;

  @override
  void initState() {
    super.initState();
    _initTrelloService();
  }

  Future<void> _initTrelloService() async {
    try {
      final trelloAuthService = TrelloAuthService();
      final token = await trelloAuthService.getStoredAccessToken() ?? '';

      if (token.isEmpty) {
        setState(() {
          _errorMessage = "No token found, please login again.";
          _isLoading = false;
        });
        return;
      }
      _trelloService = TrelloService(
        apiKey: dotenv.env['TRELLO_API_KEY'] ?? '',
        token: token,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Trello: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (_trelloService == null) {
      setState(() {
        _errorMessage = 'Trello service not initialized';
      });
      return;
    }

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cast the result to Map to access its properties
      final Map<String, dynamic> results = await _trelloService!.searchTrello(searchTerm: query);

      setState(() {
        // Combine cards, boards, and other result types
        _searchResults = [
          ...(results['cards'] ?? []),
          ...(results['boards'] ?? []),
          ...(results['members'] ?? []),
          ...(results['organizations'] ?? []),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle item selection if needed
            },
            itemBuilder: (BuildContext context) {
              return [
                CheckedPopupMenuItem<String>(
                  value: 'Cards',
                  checked: _showCards,
                  child: const Text('Cards'),
                  onTap: () {
                    setState(() {
                      _showCards = !_showCards;
                      _filterResults();
                    });
                  },
                ),
                CheckedPopupMenuItem<String>(
                  value: 'Boards',
                  checked: _showBoards,
                  child: const Text('Boards'),
                  onTap: () {
                    setState(() {
                      _showBoards = !_showBoards;
                      _filterResults();
                    });
                  },
                ),
                CheckedPopupMenuItem<String>(
                  value: 'Workspaces',
                  checked: _showWorkspaces,
                  child: const Text('Workspaces'),
                  onTap: () {
                    setState(() {
                      _showWorkspaces = !_showWorkspaces;
                      _filterResults();
                    });
                  },
                ),
                CheckedPopupMenuItem<String>(
                  value: 'Members',
                  checked: _showMembers,
                  child: const Text('Members'),
                  onTap: () {
                    setState(() {
                      _showMembers = !_showMembers;
                      _filterResults();
                    });
                  },
                ),
              ];
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Trello...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : _searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  void _filterResults() {
    setState(() {
      _searchResults = _searchResults.where((result) {
        if (_showCards && result.containsKey('idBoard')) return true;
        if (_showBoards && result.containsKey('idOrganization')) return true;
        //if (_showWorkspaces && result.containsKey('id')) return true;
        if (_showMembers && result.containsKey('username')) return true;
        return false;
      }).toList();
    });
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        print('RESULT: $result');

        // Determine the type of result and display accordingly
        String title = 'Unknown';
        String subtitle = 'No description';
        IconData icon = Icons.article;


        // Determine the type based on available fields
        if (result.containsKey('shortUrl') && result.containsKey('idBoard')) {
          // This is likely a card
          title = result['name'];
          subtitle = 'Card';
          icon = Icons.description;
        } else if (result.containsKey('idOrganization')) {
          // This is likely a board
          title = result['name'];
          subtitle = result['listName'] ?? 'Liste inconnue';
          icon = Icons.dashboard;
        } else if (result.containsKey('username')) {
          // This is likely a member
          title = result['fullName'] ?? 'Unnamed';
          subtitle = 'Member';
          icon = Icons.person;
        } else {
          title = result['displayName'];
          subtitle = 'Workspace';
          icon = Icons.workspaces;
        }

        // Include description if available
        if (result.containsKey('desc') && result['desc'] != null && result['desc'].isNotEmpty) {
          subtitle += ' - ${result['desc']}';
        }

        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: () async {
            if (_trelloService == null) return;

            if (result.containsKey('idBoard') && result.containsKey('idList') && result['idBoard'] != null && result['idList'] != null) {
              print('idList: ${result['idList']}');
              if (result['idBoard'] == null || result['idList'] == null) {
                print('Erreur : idBoard ou idList est null');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informations de carte incomplètes.')),
                );
                return;
              }
              try {
                final boardDetails = await _trelloService!.getBoardDetails(result['idBoard']);
                final listDetails = await _trelloService!.getListDetails(result['idList']);
                boardDetails['listName'] = listDetails['name']; // Mise à jour du nom du tableau

                final board = {
                  'id': boardDetails['id'],
                  'name': boardDetails['name'] ?? boardDetails['listName'] ?? 'Board',
                  'idOrganization': boardDetails['idOrganization'],
                };

                final updatedCarte = Map<String, dynamic>.from(result);
                updatedCarte['listName'] = result['listName'];

                final workspaceDetails = await _trelloService!.getWorkspaceDetails(boardDetails['idOrganization']);

                final workspace = {
                  'id': workspaceDetails['id'],
                  'displayName': workspaceDetails['displayName'] ?? 'Workspace',
                };

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkspaceDetailsScreen(workspace: workspace),
                  ),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ListesScreen(tableau: board, workspace: workspace),
                  ),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailCarteScreen(carte: updatedCarte),
                  ),
                );
              } catch (e) {
                print('Erreur lors de la navigation vers les détails de la carte : $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible de charger les détails.')),
                );
              }
              return;
            }

            if (result.containsKey('id') && result.containsKey('idOrganization')) {
              try {
                final workspace = await _trelloService!.getWorkspaceDetails(result['idOrganization']);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ListesScreen(
                      tableau: result,
                      workspace: {
                        'id': workspace['id'],
                        'displayName': workspace['displayName'],
                      },
                    ),
                  ),
                );
              } catch (e) {
                print('Erreur : $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible de charger le tableau')),
                );
              }
              return;
            }

            if (result.containsKey('displayName') && result.containsKey('id')) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WorkspaceDetailsScreen(workspace: result),
                ),
              );
              return;
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
