import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'listes.dart';

class WorkspaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;
  final TrelloService? trelloService;

  const WorkspaceDetailsScreen({Key? key, required this.workspace, this.trelloService}) : super(key: key);

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
      if (widget.trelloService != null) {
        _trelloService = widget.trelloService!;
        await _loadTableaux();
        return;
      }
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
      setState(() {
        _errorMessage = 'TrelloService not initialized';
        _isLoading = false;
      });
      return;
    }
    try {
      final tableaux = await _trelloService!.getBoardsForWorkspace(widget.workspace['id']);

      for (var tableau in tableaux) {
        print("Tableau : ${tableau['name']}, Visibilité : ${tableau['prefs']?['permissionLevel'] ?? 'Inconnu'}");
      }

      setState(() {
        _tableaux = tableaux;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des tableaux: $e';
        _isLoading = false;
      });
    }
  }

  void _ajouterTableau() {
    _tableauNameController.clear();
    _tableauDescriptionController.clear();
    _listesTemp = [];
    String selectedVisibility = "private";

    // For template handling
    final TextEditingController searchController = TextEditingController();
    int selectedTabIndex = 0;
    List<dynamic> templates = [];
    List<dynamic> filteredTemplates = [];
    String? selectedTemplateId;
    String? selectedTemplateName;
    String? selectedTemplateDesc;
    bool isLoadingTemplates = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Load templates in the background
            _trelloService?.getBoardTemplates().then((loadedTemplates) {
              if (mounted && isLoadingTemplates) {
                setStateModal(() {
                  templates = loadedTemplates;
                  filteredTemplates = [...templates];
                  isLoadingTemplates = false;
                });
              }
            }).catchError((e) {
              if (mounted && isLoadingTemplates) {
                setStateModal(() {
                  isLoadingTemplates = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load templates: $e')),
                );
              }
            });

            void filterTemplates(String query) {
              setStateModal(() {
                if (query.isEmpty) {
                  filteredTemplates = [...templates];
                } else {
                  filteredTemplates = templates.where((template) {
                    final name = template['name'].toString().toLowerCase();
                    final desc = (template['desc'] ?? '').toString().toLowerCase();
                    return name.contains(query.toLowerCase()) ||
                        desc.contains(query.toLowerCase());
                  }).toList();
                }
              });
            }

            void selectTemplate(dynamic template) {
              setStateModal(() {
                selectedTemplateId = template['id'];
                selectedTemplateName = template['name'];
                selectedTemplateDesc = template['desc'];

                // Pre-fill name and description fields with template values
                _tableauNameController.text = selectedTemplateName ?? '';
                _tableauDescriptionController.text = selectedTemplateDesc ?? '';
              });
            }

            Widget buildFromScratchTab() {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _tableauNameController,
                      decoration: const InputDecoration(labelText: 'Nom du tableau'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tableauDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
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
              );
            }

            Widget buildTemplateTab() {
              // Show loading indicator if templates are still loading
              if (isLoadingTemplates) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des modèles...'),
                    ],
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher des modèles',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: filterTemplates,
                    ),
                  ),

                  // Template carousel
                  SizedBox(
                    height: 220, // Height that accommodates 16:9 ratio cards plus margins
                    child: filteredTemplates.isEmpty
                        ? const Center(child: Text('Aucun modèle trouvé'))
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = filteredTemplates[index];
                        final isSelected = template['id'] == selectedTemplateId;

                        // Get the smallest appropriate background image URL
                        String? backgroundImageUrl;
                        if (template['prefs'] != null &&
                            template['prefs']['backgroundImageScaled'] != null &&
                            template['prefs']['backgroundImageScaled'] is List &&
                            template['prefs']['backgroundImageScaled'].isNotEmpty) {

                          // Find a scaled image that's appropriate for thumbnails
                          final scaledImages = template['prefs']['backgroundImageScaled'];

                          // Try to find a medium-sized image (around 480px width)
                          var mediumImage = scaledImages.firstWhere(
                                (img) => img['width'] >= 480 && img['width'] <= 960,
                            orElse: () => null,
                          );

                          if (mediumImage != null) {
                            backgroundImageUrl = mediumImage['url'];
                          } else if (scaledImages.isNotEmpty) {
                            // If no suitable image, use the smallest one
                            backgroundImageUrl = scaledImages.first['url'];
                          }
                        }

                        return GestureDetector(
                          onTap: () => selectTemplate(template),
                          child: Container(
                            width: 200, // Set a fixed width for the card
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                              color: isSelected ? Colors.blue.withAlpha(30) : Colors.grey.shade200,
                              image: backgroundImageUrl != null
                                  ? DecorationImage(
                                image: NetworkImage(backgroundImageUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha(80),
                                  BlendMode.darken,
                                ),
                              )
                                  : null,
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9, // Enforce 16:9 aspect ratio
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(130),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(7),
                                          bottomRight: Radius.circular(7),
                                        ),
                                      ),
                                      child: Text(
                                        template['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (selectedTabIndex == 1 && selectedTemplateId != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTemplateName ?? 'Modèle sélectionné',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (selectedTemplateDesc != null && selectedTemplateDesc!.isNotEmpty)
                            Text(
                              selectedTemplateDesc!,
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Board name and description fields
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _tableauNameController,
                      decoration: const InputDecoration(labelText: 'Nom du tableau'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _tableauDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
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
                ],
              );
            }

            return AlertDialog(
              title: const Text('Créer un tableau'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tab selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setStateModal(() => selectedTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTabIndex == 0 ? Colors.blue : Colors.grey,
                                    width: selectedTabIndex == 0 ? 2 : 1,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'À partir de zéro',
                                  style: TextStyle(
                                    fontWeight: selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                    color: selectedTabIndex == 0 ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setStateModal(() => selectedTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selectedTabIndex == 1 ? Colors.blue : Colors.grey,
                                    width: selectedTabIndex == 1 ? 2 : 1,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'À partir d\'un modèle',
                                  style: TextStyle(
                                    fontWeight: selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                    color: selectedTabIndex == 1 ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tab content
                    Flexible(
                      child: SingleChildScrollView(
                        child: selectedTabIndex == 0
                            ? buildFromScratchTab()
                            : buildTemplateTab(),
                      ),
                    ),
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
                        if (selectedTabIndex == 1 && selectedTemplateId != null) {
                          // Create board from template
                          final newTableau = await _trelloService!.createBoardFromTemplate(
                            name: _tableauNameController.text,
                            templateId: selectedTemplateId!,
                            idOrganization: widget.workspace['id'],
                          );

                          // Add lists if needed (though templates usually come with lists)
                          for (var liste in _listesTemp) {
                            await _trelloService!.createList(
                              boardId: newTableau['id'],
                              name: liste['nom'],
                            );
                          }

                          setState(() {
                            _tableaux.add(newTableau);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tableau créé à partir du modèle : ${selectedTemplateName ?? "Modèle sélectionné"}')),
                          );
                        } else {
                          // Create board from scratch
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
                        }

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
                  child: const Text('Créer'),
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
                      final updatedTableau = await _trelloService!.updateBoard(
                        boardId: _tableaux[index]['id'],
                        name: _tableauNameController.text,
                        desc: _tableauDescriptionController.text.isNotEmpty
                            ? _tableauDescriptionController.text
                            : null,
                      );
                      if (updatedTableau['prefs']['permissionLevel'] != currentVisibility) {
                        await _trelloService!.updateBoardVisibility(
                          boardId: _tableaux[index]['id'],
                          visibility: currentVisibility,
                        );
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
                                    subtitle: tableau['desc'] != null && tableau['desc'].toString().isNotEmpty
                                        ? Text(
                                        tableau['desc'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                    ) : null,
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
        ]
      )
    );
  }
}
