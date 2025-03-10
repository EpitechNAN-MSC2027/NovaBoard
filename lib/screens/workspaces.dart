import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'workspace_details.dart';

class WorkspacesScreen extends StatefulWidget {
  const WorkspacesScreen({Key? key}) : super(key: key);

  @override
  WorkspacesScreenState createState() => WorkspacesScreenState();
}

class WorkspacesScreenState extends State<WorkspacesScreen> {
  TrelloService? _trelloService;


  List<dynamic> _workspaces = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _workspaceNameController = TextEditingController();
  final TextEditingController _workspaceDescriptionController = TextEditingController();

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
      print('TrelloService is initialized with API Key & Token');

      await _loadWorkspaces();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Trello: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkspaces() async {
    if (_trelloService == null) {
      print("TrelloService is not initialized !");
      return;
    }
    try {
      final workspaces = await _trelloService!.getWorkspaces();
      setState(() {
        _workspaces = workspaces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading workspaces: $e';
        print(_errorMessage);
        _isLoading = false;
      });
    }
  }

  void _ajouterWorkspace() {
    _workspaceNameController.clear();
    _workspaceDescriptionController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create new workspace'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _workspaceNameController,
                decoration: const InputDecoration(labelText: 'Name of workspace'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _workspaceDescriptionController,
                decoration: const InputDecoration(labelText: 'Description of workspace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_workspaceNameController.text.isNotEmpty) {
                  try {
                    final newWorkspace = await _trelloService!.createWorkspace(
                      name: _workspaceNameController.text,
                      displayName: _workspaceNameController.text,
                      desc: _workspaceDescriptionController.text.isNotEmpty
                          ? _workspaceDescriptionController.text
                          : null,
                    );

                    setState(() {
                      _workspaces.add(newWorkspace);
                    });

                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating new workspace: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editerWorkspace(int index) {
    _workspaceNameController.text = _workspaces[index]['displayName'] ?? 'No name';
    _workspaceDescriptionController.text = _workspaces[index]['desc'] ?? 'No description';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modify workspace'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _workspaceNameController,
                decoration: const InputDecoration(labelText: 'Workspace name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _workspaceDescriptionController,
                decoration: const InputDecoration(labelText: 'Workspace description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
        try {


        final updatedWorkspace = await _trelloService!.updateWorkspace(
        workspaceId: _workspaces[index]['id'],
          displayName: _workspaceNameController.text,
        desc: _workspaceDescriptionController.text.isNotEmpty
        ? _workspaceDescriptionController.text
            : null,
        );

                  setState(() {
                    _workspaces[index] = updatedWorkspace;
                  });

                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating workspace: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _supprimerWorkspace(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete workspace'),
          content: const Text('Are you sure you want to delete this workspace?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await _trelloService!.deleteWorkspace(_workspaces[index]['id']);

        if (mounted) {
          setState(() {
            _workspaces.removeAt(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workspace deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting workspace: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Workspaces',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black, size: 30),
                        onPressed: _ajouterWorkspace,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage.isNotEmpty)
                  Center(child: Text(_errorMessage))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _workspaces.length,
                      itemBuilder: (context, index) {
                        final workspace = _workspaces[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: Colors.white.withAlpha((0.8 * 255).toInt()),
                            child: ListTile(
                              leading: const Icon(Icons.workspaces, color: Colors.deepPurple),
                              title: Text(workspace['displayName'] ?? 'No name'),
                              subtitle: Text(workspace['desc'] ?? 'No Description'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editerWorkspace(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _supprimerWorkspace(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WorkspaceDetailsScreen(workspace: workspace),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}