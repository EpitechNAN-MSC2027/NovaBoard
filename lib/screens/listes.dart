import 'package:flutter/material.dart';
import 'detail_carte.dart';

class ListesScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;
  final Map<String, dynamic> tableaux;

  const ListesScreen({
    Key? key,
    required this.workspace,
    required this.tableaux
  }) : super(key: key);

  @override
  ListesScreenState createState() => ListesScreenState();
}

class ListesScreenState extends State<ListesScreen> {
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardDescriptionController = TextEditingController();

  Map<String, dynamic>? _selectedTableau;

  @override
  void initState() {
    super.initState();
    if (widget.workspace['tableaux'] != null && widget.workspace['tableaux'].isNotEmpty) {
      _selectedTableau = widget.tableaux;
    }
    else {
      _selectedTableau = {'nom': 'Aucun tableau sélectionné', 'listes': []};
    }
  }

  /// **Ajouter une carte à une liste**
  void _ajouterCarte(Map<String, dynamic> liste) {
    _cardNameController.clear();
    _cardDescriptionController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une carte'),
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
              onPressed: () {
                if (_cardNameController.text.isNotEmpty) {
                  setState(() {
                    liste['cartes'].add({
                      'nom': _cardNameController.text,
                      'description': _cardDescriptionController.text,
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
  }

  @override
  Widget build(BuildContext context) {
    var tableaux = widget.workspace['tableaux'] ?? [];

    if (tableaux.isNotEmpty && tableaux[0] is String) {
      tableaux = tableaux.map((e) => {'nom': e, 'listes': []}).toList();
    }
    print("tableaux après conversion : $tableaux");

    if (_selectedTableau!['liste'] != null) {
      _selectedTableau!['liste'] = (_selectedTableau!['liste'] as List)
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
    ),Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: DropdownButton<Map<String, dynamic>>(
          value: _selectedTableau,
          onChanged: (newValue) {
            setState(() {
              _selectedTableau = newValue;
            });
          },
          items: tableaux.map<DropdownMenuItem<Map<String, dynamic>>>((tableau) {
            print("Valeur actuelle de tableau dans map(): $tableau");

            return DropdownMenuItem<Map<String, dynamic>>(
              value: tableau,
              child: Text(tableau['nom']),
            );
          }).toList(),
        ),
      ),
      body: _selectedTableau == null
          ? const Center(child: Text("Aucun tableau disponible"))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._selectedTableau!['liste']?.map<Widget>((liste) {
              print("Liste affichée : $liste");
              return Container(
                width: 300, // Pour occuper plus de place
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
                        liste['nom'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {}, // Fonction pour éditer la liste
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {}, // Fonction pour supprimer la liste
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: liste['cartes'].length,
                        itemBuilder: (context, index) {
                          final carte = liste['cartes'][index];
                          return Card(
                            child: ListTile(
                              title: Text(carte['nom']),
                              subtitle: Text(carte['description']),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailCarteScreen(carte: carte),
                                  ),
                                );
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {}, // Modifier une carte
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {}, // Supprimer une carte
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Ajout du bouton "+" en bas de chaque liste
                    TextButton.icon(
                      onPressed: () => _ajouterCarte(liste),
                      icon: const Icon(Icons.add, color: Colors.deepPurple),
                      label: const Text('Add Card'),
                    ),
                  ],
                ),
              );
            }) ?? [],
          ],
        ),
      ),
    )
        ]
    );
  }
}