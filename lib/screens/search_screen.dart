import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'workspace_details.dart';
import 'listes.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreen createState() => _SearchScreen();
}

class _SearchScreen extends State<SearchScreen> {
  TrelloService? _trelloService;
  TextEditingController _searchController = TextEditingController();
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
      appBar: AppBar(
        title: const Text('Trello Search'),
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
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
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
          subtitle = 'Board';
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
          onTap: () {
            if (result.containsKey('idBoard')) {
              // This is likely a board
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListesScreen(
                    workspace: workspace,
                    tableau: result,
                  ),
                ),
              );*/
            } else if (result.containsKey('idList')) {
              // This is likely a card
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardDetailsScreen(card: result),
                ),
              );*/
            } else if (result.containsKey('id')) {
              // This is likely a workspace
              /*Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkspaceDetailsScreen(workspace: result),
                ),
              ).then((_) {
                // When navigating back, set the selected index to the WorkspacesScreen
                navigationKey.currentState?.setSelectedIndex(0);
              });*/
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
