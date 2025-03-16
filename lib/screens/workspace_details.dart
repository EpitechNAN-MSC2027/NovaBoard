import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import '../screens/listes.dart';

class WorkspaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;

  const WorkspaceDetailsScreen({Key? key, required this.workspace}) : super(key: key);

  @override
  WorkspaceDetailsScreenState createState() => WorkspaceDetailsScreenState();
}


class WorkspaceDetailsScreenState extends State<WorkspaceDetailsScreen> {
  TrelloService? _trelloService;

  List<dynamic> _tableaux = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  final TextEditingController _tableauNameController = TextEditingController();
  final TextEditingController _tableauDescriptionController = TextEditingController();

  List<Map<String, dynamic>> _listesTemp = [];
  final TextEditingController _listNameController = TextEditingController();

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

      await _loadTableaux();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Trello: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableaux() async {
    if (_trelloService == null) {
      print("TrelloService is not initialized!");
      setState(() {
        _errorMessage = 'TrelloService not initialized';
        _isLoading = false;
      });
      return;
    }
    try {
      print("Chargement des tableaux pour workspace: ${widget.workspace['id']}");
      final tableaux = await _trelloService!.getBoardsForWorkspace(widget.workspace['id']);

      for (var tableau in tableaux) {
        print("Tableau : ${tableau['name']}, Visibilité : ${tableau['prefs']?['permissionLevel'] ?? 'Inconnu'}");
      }

      setState(() {
        _tableaux = tableaux;
        _isLoading = false;
      });

      print("Tableaux chargés avec succès !");
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des tableaux: $e';
        _isLoading = false;
      });
      print("Erreur lors du chargement des tableaux: $e");
    }
  }

  void _ajouterTableau() {
    _tableauNameController.clear();
    _tableauDescriptionController.clear();
    _listesTemp = [];
    String selectedVisibility = "private";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Créer un tableau'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tableauNameController,
                      decoration: const InputDecoration(labelText: 'Nom du tableau'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tableauDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Visibilité :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedVisibility,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateModal(() {
                                selectedVisibility = newValue;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: "private",
                              child: Text("Privé"),
                            ),
                            DropdownMenuItem(
                              value: "public",
                              child: Text("Public"),
                            ),
                            DropdownMenuItem(
                              value: "org",
                              child: Text("Organisation"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _listNameController,
                      decoration: const InputDecoration(labelText: 'Nom de la liste'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_listNameController.text.isNotEmpty) {
                          setStateModal(() {
                            _listesTemp.add({
                              'nom': _listNameController.text,
                              'cartes': []
                            });
                            _listNameController.clear();
                          });
                        }
                      },
                      child: const Text('Ajouter une liste'),
                    ),
                    const SizedBox(height: 10),
                    ..._listesTemp.map((list) => ListTile(
                      title: Text(list['nom']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateModal(() {
                            _listesTemp.remove(list);
                          });
                        },
                      ),
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_tableauNameController.text.isNotEmpty) {
                      try {
                        final newTableau = await _trelloService!.createBoard(
                          name: _tableauNameController.text,
                          desc: _tableauDescriptionController.text.isNotEmpty
                              ? _tableauDescriptionController.text
                              : null,
                          idOrganization: widget.workspace['id'],
                          prefs: selectedVisibility,
                        );

                        for (var liste in _listesTemp) {
                          await _trelloService!.createList(
                            boardId: newTableau['id'],
                            name: liste['nom'],
                          );
                        }
                        setState(() {
                          _tableaux.add(newTableau);
                        });

                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de la création du tableau: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editerTableau(int index) {
    _tableauNameController.text = _tableaux[index]['name'] ?? 'Sans nom';
    _tableauDescriptionController.text = _tableaux[index]['desc'] ?? 'Sans description';
    String currentVisibility = _tableaux[index]['prefs']?['permissionLevel'] ?? 'private';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Modifier le tableau'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tableauNameController,
                    decoration: const InputDecoration(labelText: 'Nom du tableau'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tableauDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Visibilité :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: currentVisibility,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateModal(() {
                              currentVisibility = newValue;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: "private",
                            child: Text("Privé"),
                          ),
                          DropdownMenuItem(
                            value: "public",
                            child: Text("Public"),
                          ),
                          DropdownMenuItem(
                            value: "org",
                            child: Text("Organisation"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      print("Mise à jour du tableau : ${_tableaux[index]['id']}");
                      print("Nouvelle visibilité : $currentVisibility");
                      final updatedTableau = await _trelloService!.updateBoard(
                        boardId: _tableaux[index]['id'],
                        name: _tableauNameController.text,
                        desc: _tableauDescriptionController.text.isNotEmpty
                            ? _tableauDescriptionController.text
                            : null,
                      );
                      if (updatedTableau['prefs']['permissionLevel'] != currentVisibility) {
                        print(" Mise à jour de la visibilité...");
                        await _trelloService!.updateBoardVisibility(
                          boardId: _tableaux[index]['id'],
                          visibility: currentVisibility,
                        );
                        print("Visibilité mise à jour !");
                      }
                      await _loadTableaux();
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de la modification du tableau: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _supprimerTableau(int index) async {

    if (_trelloService == null) {
      print(" TrelloService is not initialized!");
      return;
    }

    if (index < 0 || index >= _tableaux.length) return;
    String boardId = _tableaux[index]['id'];

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le tableau'),
          content: const Text('Voulez-vous vraiment supprimer ce tableau ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        print("Suppression du tableau avec ID: $boardId");
        await _trelloService!.deleteBoard(boardId);

        await _loadTableaux();

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tableau supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur lors de la suppression du tableau: $e')),
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/FondApp.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Tableaux',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                                filled: true,
                                fillColor: Colors.white.withAlpha((0.8 * 255).toInt()),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black, size: 30),
                        onPressed: _ajouterTableau,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  if (_errorMessage.isNotEmpty)
                    Center(child: Text(_errorMessage))
                  else
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final tableauxFiltres = _tableaux.where((t) => t['name']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false).toList();
                          return ListView.builder(
                            itemCount: tableauxFiltres.length,
                            itemBuilder: (context, index) {
                              final tableau = tableauxFiltres[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.white.withAlpha(
                                  (0.8 * 255).toInt()),
                              child: ListTile(
                                leading: const Icon(
                                    Icons.assignment, color: Colors.deepPurple),
                                title: Text(tableau['name'] ?? 'Sans nom'),
                                subtitle: Text(
                                    tableau['desc'] ?? 'Sans description'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ListesScreen(
                                            workspace: widget.workspace,
                                            tableau: tableau,
                                          ),
                                    ),
                                  );
                                  _loadTableaux();
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.edit, color: Colors.blue),
                                      onPressed: () => _editerTableau(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete, color: Colors.red),
                                      onPressed: () => _supprimerTableau(index),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
    ),
            ),
    ],
    ),
      ),
    ]));
  }
}