import 'package:flutter/material.dart';
import 'detail_tableau.dart';

class TableauScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;

  const TableauScreen({
    Key? key,
    required this.workspace,
  }) : super(key: key);

  @override
  TableauScreenState createState() => TableauScreenState();
}

class TableauScreenState extends State<TableauScreen> {
  final TextEditingController _tableauNameController = TextEditingController();
  final TextEditingController _tableauDescriptionController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();

  List<Map<String, dynamic>> _listsTemp = [];
  String _searchQuery = '';

  /// **Ajoute un tableau avec des listes**
  void _ajouterTableau() {
    _tableauNameController.clear();
    _tableauDescriptionController.clear();
    _listsTemp = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Créer un nouveau tableau'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tableauNameController,
                      decoration: const InputDecoration(labelText: 'Nom du tableau'),
                    ),
                    TextField(
                      controller: _tableauDescriptionController,
                      decoration: const InputDecoration(labelText: 'Description du tableau'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _listNameController,
                      decoration: const InputDecoration(labelText: 'Ajouter une liste'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_listNameController.text.isNotEmpty) {
                          setStateModal(() {
                            _listsTemp.add({'nom': _listNameController.text, 'cartes': []});
                            _listNameController.clear();
                          });
                        }
                      },
                      child: const Text('Ajouter une liste'),
                    ),
                    const SizedBox(height: 10),
                    ..._listsTemp.map((list) => ListTile(
                      title: Text(list['nom']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateModal(() {
                            _listsTemp.remove(list);
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
                  onPressed: () {
                    if (_tableauNameController.text.isNotEmpty &&
                        _tableauDescriptionController.text.isNotEmpty) {
                      setState(() {
                        widget.workspace['tableaux'].add({
                          'nom': _tableauNameController.text,
                          'description': _tableauDescriptionController.text,
                          'listes': List<Map<String, dynamic>>.from(_listsTemp),
                        });
                      });
                      Navigator.of(context).pop();
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

  /// **Modifier un tableau**
  void _editerTableau(Map<String, dynamic> tableau) {
    _tableauNameController.text = tableau['nom'];
    _tableauDescriptionController.text = tableau['description'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier le tableau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tableauNameController,
                decoration: const InputDecoration(labelText: 'Nom du tableau'),
              ),
              TextField(
                controller: _tableauDescriptionController,
                decoration: const InputDecoration(labelText: 'Description du tableau'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tableau['nom'] = _tableauNameController.text;
                  tableau['description'] = _tableauDescriptionController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  /// **Supprimer un tableau**
  void _supprimerTableau(Map<String, dynamic> tableau) {
    setState(() {
      widget.workspace['tableaux'].remove(tableau);
    });
  }

  /// **Afficher les détails du tableau**
  void _afficherListesTableau(Map<String, dynamic> tableau) {
    if (tableau.containsKey('listes') && tableau['listes'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailTableauScreen(tableau: tableau),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune liste trouvée dans ce tableau')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTableaux = (widget.workspace['tableaux'] ?? [])
        .where((tableau) =>
        (tableau['nom'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
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
          Expanded(
            child: ListView.builder(
              itemCount: filteredTableaux.length,
              itemBuilder: (context, index) {
                final tableau = filteredTableaux[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.white.withAlpha((0.8 * 255).toInt()),
                    child: ListTile(
                      leading: const Icon(
                        Icons.view_list,
                        color: Colors.deepPurple,
                      ),
                      title: Text(tableau['nom']),
                      subtitle: Text('Listes: ${(tableau['listes'] ?? []).length}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _editerTableau(tableau),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _supprimerTableau(tableau),
                          ),
                        ],
                      ),
                      onTap: () {
                        _afficherListesTableau(tableau);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}