import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'detail_carte.dart';

class DragContext {
  final Map<String, dynamic> card;
  final Map<String, dynamic> sourceList;
  final int cardIndex;

  DragContext({required this.card, required this.sourceList, required this.cardIndex});
}

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

  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  String? _autoScrollDirection;
  Offset? _lastDragPosition;
  PageController _pageController = PageController(viewportFraction: 0.97);
  DragContext? _dragContext;
  bool _isDragging = false;

  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardDescriptionController = TextEditingController();

  Map<String, dynamic>? _selectedTableau;

  @override
  void initState() {
    super.initState();
    _initTrelloService();
  }

  @override
  void dispose() {
    _cancelAutoScroll();
    _pageController.dispose();
    super.dispose();
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
      print("Chargement des listes pour le tableau ${widget.tableau['id']}");
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
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une carte'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Date limite : "),
                        Text(selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : "Non définie"),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
                      due: selectedDate?.toIso8601String(),
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

  void _editerCarte(String cardId, String currentName, String currentDesc, String? currentDate) {
    _cardNameController.text = currentName;
    _cardDescriptionController.text = currentDesc;

    DateTime? selectedDate = currentDate != null
        ? DateTime.parse(currentDate) : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la carte'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Date limite : "),
                        Text(selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : "Non définie"),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
                    due: selectedDate?.toIso8601String(),
                  );

                  final updatedCard = await _trelloService!.getCard(cardId);

                  setState(() {
                    for (var liste in _listes) {
                      for (int i = 0; i < liste['cartes'].length; i++) {
                        if (liste['cartes'][i]['id'] == cardId) {
                          liste['cartes'][i] = updatedCard;
                          break;
                        }
                      }
                    }
                  });

                  if (context.mounted) Navigator.of(context).pop();
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

  // Start auto-scrolling in the specified direction
  void _startAutoScroll(String direction, double screenWidth) {
    const scrollSpeed = 8.0; // Extraire en constante

    _isAutoScrolling = true;
    _autoScrollDirection = direction;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isDragging) {
        _cancelAutoScroll();
        return;
      }

      final leftEdge = screenWidth * 0.1;
      final rightEdge = screenWidth * 0.9;

      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject != null && renderObject is RenderBox) {
        // Convertir les coordonnées de l'écran en coordonnées locales
        final localPosition = renderObject.globalToLocal(_lastDragPosition!);

        // Vérifier si la position du doigt est sortie de la zone de défilement
        if (localPosition.dx >= leftEdge && localPosition.dx <= rightEdge) {
          _cancelAutoScroll();
          return;
        }
      }

      // Arrêter le défilement si on n'est plus près du bord
      if (_lastDragPosition!.dx >= leftEdge && _lastDragPosition!.dx <= rightEdge) {
        _cancelAutoScroll();
        return;
      }

      if (direction == 'left' && _pageController.page! > 0) {
        _pageController.jumpTo(_pageController.offset - scrollSpeed);
      } else if (direction == 'right' && _pageController.page! < _listes.length - 1) {
        _pageController.jumpTo(_pageController.offset + scrollSpeed);
      } else {
        _cancelAutoScroll();
      }
    });
  }

  // Cancel auto-scrolling
  void _cancelAutoScroll() {
    print("CANCEL AUTO SCROLL");
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _isAutoScrolling = false;
    _autoScrollDirection = null;
  }

  // Handle dropping a card onto a new list
  Future<void> _handleCardDrop(Map<String, dynamic> draggedCard, Map<String, dynamic> targetList) async {
    if (_dragContext == null) return;

    // Ne rien faire si déposé sur la même liste
    if (_dragContext!.sourceList['id'] == targetList['id']) return;

    // Ajouter la carte à la liste cible immédiatement pour le feedback visuel
    setState(() {
      if (targetList['cartes'] == null) {
        targetList['cartes'] = [];
      }

      targetList['cartes'].add({
        ...draggedCard,
        '_isNewlyAdded': true, // Marquer comme nouvellement ajoutée pour l'animation
      });
    });

    try {
      // Mettre à jour la carte pour la déplacer vers la nouvelle liste via l'API Trello
      await _trelloService!.updateCard(
        cardId: draggedCard['id'],
        idList: targetList['id'],
      );

      setState(() {
        // Supprimer de la liste source
        _dragContext!.sourceList['cartes'].removeAt(_dragContext!.cardIndex);

        // Supprimer le flag temporaire pour l'animation
        for (var i = 0; i < targetList['cartes'].length; i++) {
          if (targetList['cartes'][i]['id'] == draggedCard['id']) {
            targetList['cartes'][i].remove('_isNewlyAdded');
            break;
          }
        }
      });

      _showFeedback('Carte déplacée avec succès', isError: false);
    } catch (e) {
      // Annuler les changements visuels en cas d'erreur
      setState(() {
        targetList['cartes'].removeWhere((card) =>
        card['id'] == draggedCard['id'] && card['_isNewlyAdded'] == true);
      });

      _showFeedback('Erreur lors du déplacement de la carte: $e', isError: true);
    } finally {
      // Réinitialiser le suivi du glissement
      _dragContext = null;
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 1),
      ),
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
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _listes.length,
                    pageSnapping: true,
                    itemBuilder: (context, index) {
                      var liste = _listes[index];

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
                                child: DragTarget<Map<String, dynamic>>(
                                  onWillAccept: (data) {
                                    return data != null;
                                  },
                                  onAccept: (draggedCard) {
                                    _cancelAutoScroll();
                                    _handleCardDrop(draggedCard, liste);
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: candidateData.isNotEmpty
                                            ? Colors.deepPurple.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: candidateData.isNotEmpty
                                            ? Border.all(color: Colors.deepPurple, width: 1.0)
                                            : null,
                                      ),
                                      child: ListView.builder(
                                        itemCount: (liste['cartes'] ?? []).length,
                                        itemBuilder: (context, cardIndex) {
                                          final cartes = liste['cartes'] ?? [];
                                          final carte = cartes.isNotEmpty ? cartes[cardIndex] : null;

                                          if (carte == null) return const SizedBox();

                                          return LongPressDraggable<Map<String, dynamic>>(
                                            data: carte,
                                            delay: const Duration(milliseconds: 500),
                                            feedback: Material(
                                              elevation: 8.0, // Increased for more pronounced shadow
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: Container(
                                                width: 300,
                                                padding: const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  border: Border.all(color: Colors.deepPurple, width: 2.0),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 10.0,
                                                      spreadRadius: 1.0,
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  title: Text(
                                                    carte['name'] ?? "Sans titre",
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  subtitle: carte['desc'] != null && carte['desc'].toString().isNotEmpty
                                                      ? Text(
                                                    carte['desc'],
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.5,
                                              child: Card(
                                                child: ListTile(
                                                  leading: Checkbox(
                                                    value: carte['dueComplete'] == true,
                                                    onChanged: (bool? value) async {
                                                      final updated = {...carte, 'dueComplete': value};
                                                      try {
                                                        await _trelloService!.updateCard(
                                                          cardId: carte['id'],
                                                          dueComplete: value.toString(),
                                                        );
                                                        setState(() {
                                                          carte['dueComplete'] = value;
                                                        });
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Erreur lors de la mise à jour du statut: $e')),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  title: Text(carte['name'] ?? "Sans titre"),
                                                  subtitle: carte['desc'] != null && carte['desc'].toString().isNotEmpty
                                                  ? Text(
                                                    carte['desc'],
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ) : null,
                                                ),
                                              ),
                                            ),
                                            onDragStarted: () {
                                              if (carte != null) {
                                                setState(() {
                                                  _isDragging = true;
                                                  _dragContext = DragContext(
                                                      card: carte,
                                                      sourceList: liste,
                                                      cardIndex: cardIndex
                                                  );
                                                });
                                              }
                                            },
                                            onDragUpdate: (details) {
                                              // Assurez-vous que cette méthode est bien appelée avec des logs
                                              print("DRAG UPDATE: ${details.globalPosition}");
                                              _lastDragPosition = details.globalPosition; // Mettre à jour directement ici
                                            },
                                            onDragEnd: (details) {
                                              _isDragging = false; // Important: marquer la fin du glissement
                                              _cancelAutoScroll();
                                              _lastDragPosition = null;
                                            },
                                            child: Card(
                                                child: ListTile(
                                                  leading: Checkbox(
                                                    value: carte['dueComplete'] == true,
                                                    onChanged: (bool? value) async {
                                                      final updated = {...carte, 'dueComplete': value};
                                                      try {
                                                        await _trelloService!.updateCard(
                                                          cardId: carte['id'],
                                                          dueComplete: value.toString(),
                                                        );
                                                        setState(() {
                                                          carte['dueComplete'] = value;
                                                        });
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Erreur lors de la mise à jour du statut: $e')),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  title: Text(carte['name'] ?? "Sans titre"),
                                                subtitle: carte['desc'] != null && carte['desc'].toString().isNotEmpty
                                                ? Text(
                                                  carte['desc'],
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ) : null,
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
                                                      _editerCarte(carte['id'], carte['name'], carte['desc'], carte['due']);
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
                                            ),
                                          );
                                        },
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
                  ),
        ),
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (PointerMoveEvent event) {
              if (_isDragging) {
                print("POINTER MOVE: ${event.position}");
                _lastDragPosition = event.position;

                // Appliquer la même logique que _handleDragUpdate
                final screenWidth = MediaQuery.of(context).size.width;
                final position = event.position.dx;
                final leftEdge = screenWidth * 0.1;
                final rightEdge = screenWidth * 0.9;

                if (position < leftEdge) {
                  if (_autoScrollDirection != 'left' && _pageController.page! > 0) {
                    _cancelAutoScroll();
                    _startAutoScroll('left', screenWidth);
                  }
                } else if (position > rightEdge) {
                  if (_autoScrollDirection != 'right' && _pageController.page! < _listes.length - 1) {
                    _cancelAutoScroll();
                    _startAutoScroll('right', screenWidth);
                  }
                } else {
                  _cancelAutoScroll();
                }
              }
            },
            child: Container(), // Widget transparent
          ),
        ),
      ]
    );
  }
}