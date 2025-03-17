import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'detail_carte.dart';

class ListesScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;
  final Map<String, dynamic> tableau;

  const ListesScreen({
    Key? key,
    required this.workspace,
    required this.tableau,
  }) : super(key: key);

  @override
  ListesScreenState createState() => ListesScreenState();
}

class ListesScreenState extends State<ListesScreen> {
  TrelloService? _trelloService;
  List<dynamic> _listes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardDescriptionController = TextEditingController();

  Map<String, dynamic>? _selectedTableau;

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

      await _loadListes();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Trello: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadListes() async {
    if (_trelloService == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("📥 Chargement des listes pour le tableau ${widget.tableau['id']}");
      final listes = await _trelloService!.getListsForBoard(widget.tableau['id']);

      for (var liste in listes) {
        final cartes = await _trelloService!.getCardsForList(liste['id']);
        liste['cartes'] = cartes ?? [];
      }

      setState(() {
        _listes = listes;
        _isLoading = false;
      });

      print("Listes et cartes récupérées avec succès !");
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors du chargement des listes et cartes : $e";
        _isLoading = false;
      });
      print(" Erreur lors du chargement des listes et cartes : $e");
    }
  }

  void _ajouterListe() {
    _listNameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créer une liste'),
          content: TextField(
            controller: _listNameController,
            decoration: const InputDecoration(labelText: 'Nom de la liste'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_listNameController.text.isNotEmpty) {
                  try {
                    final newList = await _trelloService!.createList(
                      boardId: widget.tableau['id'],
                      name: _listNameController.text,
                    );

                    setState(() {
                      _listes.add(newList);
                    });

                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de l\'ajout de la liste: $e')),
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
  }

  void _editerListe(int index) {
    _listNameController.text = _listes[index]['name'] ?? 'Sans nom';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la liste'),
          content: TextField(
            controller: _listNameController,
            decoration: const InputDecoration(labelText: 'Nom de la liste'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _trelloService!.updateList(
                    listId: _listes[index]['id'],
                    name: _listNameController.text,
                  );

                  setState(() {
                    _listes[index]['name'] = _listNameController.text;
                  });

                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la modification de la liste: $e')),
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
  }


  void _supprimerListe(int index) async {
    final listeId = _listes[index]['id'];

    try {
      await _trelloService!.archiveList(listeId);

      setState(() {
        _listes.removeAt(index);
      });

      print(" Liste supprimée !");
    } catch (e) {
      print(" Erreur suppression liste: $e");
    }
  }


  void _ajouterCarte(Map<String, dynamic> liste) {
    TextEditingController cardNameController = TextEditingController();
    TextEditingController cardDescriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une carte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNameController,
                decoration: const InputDecoration(labelText: 'Nom de la carte'),
              ),
              TextField(
                controller: cardDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                if (cardNameController.text.isNotEmpty) {
                  try {
                    final newCard = await _trelloService!.createCard(
                      listId: liste['id'],
                      name: cardNameController.text,
                      desc: cardDescriptionController.text,
                    );

                    setState(() {
                      if (liste['cartes'] == null) {
                        liste['cartes'] = [];
                      }
                      liste['cartes'].add(newCard);
                    });

                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur lors de l'ajout de la carte : $e")),
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
  }

  void _editerCarte(String cardId, String currentName, String currentDesc) {
    _cardNameController.text = currentName;
    _cardDescriptionController.text = currentDesc;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la carte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cardNameController,
                decoration: const InputDecoration(labelText: 'Nom de la carte'),
              ),
              TextField(
                controller: _cardDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
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
                  await _trelloService!.updateCard(
                    cardId: cardId,
                    name: _cardNameController.text,
                    desc: _cardDescriptionController.text,
                  );
                  print("a");
                  setState(() {
                    for (var liste in _listes ?? []) {
                      print(liste);
                      for (var card in liste['cartes'] ?? []) {
                        if (card['id'] == cardId) {
                          card['name'] = _cardNameController.text;
                          card['desc'] = _cardDescriptionController.text;
                          break;
                        }
                      }
                    }
                  });
                  print("b");

                  if (context.mounted) Navigator.of(context).pop();
                  print("c");

                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la modification de la carte: $e')),
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
  }

  void _supprimerCarte(Map<String, dynamic> liste, int index) async {
    final carteId = liste['cartes'][index]['id'];

    try {
      await _trelloService!.deleteCard(carteId);

      setState(() {
        liste['cartes'].removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carte supprimée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de la carte: $e')),
      );
    }
  }

  void _gererMembresCarte(Map<String, dynamic> carte) async {
    List<dynamic> membres = carte['idMembers'] ?? [];
    TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("👥 Membres de la Carte", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (membres.isEmpty)
                    const Text("Aucun membre assigné"),
                  ...membres.map((membreId) => ListTile(
                    title: Text(membreId),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        try {
                          await _trelloService!.removeMemberFromCard(carte['id'], membreId);
                          setStateModal(() {
                            membres.remove(membreId);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erreur lors de la suppression : $e")),
                          );
                        }
                      },
                    ),
                  )),
                  const Divider(),
                  const Text("➕ Ajouter un membre"),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "ID du membre"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isNotEmpty) {
                        try {
                          await _trelloService!.addMemberToCard(carte['id'], emailController.text);
                          setStateModal(() {
                            membres.add(emailController.text);
                          });
                          emailController.clear();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erreur lors de l'ajout : $e")),
                          );
                        }
                      }
                    },
                    child: const Text("Ajouter"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var tableaux = widget.workspace['tableaux'] ?? [];

    if (tableaux.isNotEmpty && tableaux[0] is String) {
      tableaux = tableaux.map((e) => {'nom': e, 'listes': []}).toList();
    }
    print("tableaux après conversion : $tableaux");

    if (_selectedTableau != null && _selectedTableau!['listes'] != null) {
      _selectedTableau!['listes'] = (_selectedTableau!['listes'] as List)
          .map((e) => e is String ? {'nom': e, 'cartes': []} : e)
          .toList();
    }

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
            title: Text(widget.tableau['name'] ?? "Nom inconnu"),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                 onPressed: _ajouterListe,
                tooltip: "Ajouter une liste",
    )
    ],
    ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _listes.isEmpty
                ? const Center(child: Text("Aucune liste disponible"))
                : PageView.builder(
              controller: PageController(viewportFraction: 0.97),
              scrollDirection: Axis.horizontal,
              itemCount: _listes.length,
              pageSnapping: true, // Active le snapping automatique
              itemBuilder: (context, index) {
                var liste = _listes[index];

                print("Liste affichée : $liste");
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 360,
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(150),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            liste['name'] ?? "Sans Nom",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editerListe(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _supprimerListe(index),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: (liste['cartes'] ?? []).length,
                            itemBuilder: (context, cardIndex) {
                              final cartes = liste['cartes'] ?? [];
                              final carte = cartes.isNotEmpty ? cartes[cardIndex] : null;

                              if (carte == null) return const SizedBox();

                              return Card(
                                child: ListTile(
                                  title: Text(carte['name'] ?? "Sans titre"),
                                  subtitle: Text(carte['description'] ?? "Sans titre"),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailCarteScreen(carte: carte),
                                      ),
                                    );
                                  },
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editerCarte(carte['id'], carte['name'], carte['desc']);
                                      } else if (value == 'delete') {
                                        _supprimerCarte(liste, cardIndex);
                                      } else if (value == 'manage_members') {
                                        _gererMembresCarte(carte);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('✏️ Modifier')),
                                      const PopupMenuItem(value: 'delete', child: Text('🗑️ Supprimer')),
                                      const PopupMenuItem(value: 'manage_members', child: Text('👥 Assigner des membres')),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _ajouterCarte(liste),
                          icon: const Icon(Icons.add, color: Colors.deepPurple),
                          label: const Text('Add Card'),
                      ),
                    ],
                  ),
            ),
          );
        },
    )) ]);
  }
}