import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarteScreen extends StatefulWidget {
  const CarteScreen({Key? key}) : super(key: key);

  @override
  CarteScreenState createState() => CarteScreenState();
}

class CarteScreenState extends State<CarteScreen> {
  final TextEditingController _carteController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final TextEditingController _tacheController = TextEditingController();

  final List<Map<String, dynamic>> _cartes = [];
  final List<String> _checklist = [];
  String _searchQuery = '';
  bool _sortByDate = false;

  final DateTime _dateCreation = DateTime.now();
  DateTime? _dateLimite;

  /// Fonction pour afficher la fenêtre modale de création de carte
  void _ajouterCarte() {
    _checklist.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Créer une nouvelle carte'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _carteController,
                      decoration:
                      const InputDecoration(labelText: 'Nom de la carte'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentaireController,
                      decoration: const InputDecoration(
                          labelText: 'Ajouter un commentaire'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tacheController,
                      decoration: const InputDecoration(
                          labelText: 'Ajouter une tâche à la checklist'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_tacheController.text.isNotEmpty) {
                          setStateModal(() {
                            _checklist.add(_tacheController.text);
                            _tacheController.clear();
                          });
                        }
                      },
                      child: const Text('Ajouter à la checklist'),
                    ),
                    const SizedBox(height: 10),
                    ..._checklist.map((tache) => ListTile(
                      title: Text(tache),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateModal(() {
                            _checklist.remove(tache);
                          });
                        },
                      ),
                    )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Date de création : '),
                        Text(DateFormat('dd/MM/yyyy').format(_dateCreation)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Date limite : '),
                        TextButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setStateModal(() {
                                _dateLimite = pickedDate;
                              });
                            }
                          },
                          child: Text(_dateLimite != null
                              ? DateFormat('dd/MM/yyyy').format(_dateLimite!)
                              : 'Choisir une date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_carteController.text.isNotEmpty) {
                      setState(() {
                        _cartes.add({
                          'nom': _carteController.text,
                          'dateCreation': _dateCreation,
                          'dateLimite': _dateLimite,
                          'commentaire': _commentaireController.text,
                          'checklist': List<String>.from(_checklist),
                        });
                        _carteController.clear();
                        _commentaireController.clear();
                        _tacheController.clear();
                        _dateLimite = null;
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

  void _editerCarte(Map<String, dynamic> carte) {
    _carteController.text = carte['nom'];
    _commentaireController.text = carte['commentaire'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la carte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _carteController,
                decoration: const InputDecoration(labelText: 'Nom de la carte'),
              ),
              TextField(
                controller: _commentaireController,
                decoration: const InputDecoration(labelText: 'Commentaire'),
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
                  carte['nom'] = _carteController.text;
                  carte['commentaire'] = _commentaireController.text;
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

  void _supprimerCarte(Map<String, dynamic> carte) {
    setState(() {
      _cartes.remove(carte);
    });
  }

  /// Fonction de tri des cartes par date
  void _trierParDate() {
    setState(() {
      _sortByDate = !_sortByDate;
      _cartes.sort((a, b) => _sortByDate
          ? a['dateCreation'].compareTo(b['dateCreation'])
          : b['dateCreation'].compareTo(a['dateCreation']));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCartes = _cartes
        .where((carte) => carte['nom']
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list,
                      color: Colors.black, size: 30),
                  onPressed: _trierParDate,
                  tooltip: _sortByDate
                      ? 'Tri par date croissante'
                      : 'Tri par date décroissante',
                ),
                const SizedBox(width: 10),
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
                  icon: const Icon(Icons.add,
                      color: Colors.black, size: 30),
                  onPressed: _ajouterCarte,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCartes.length,
              itemBuilder: (context, index) {
                final carte = filteredCartes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 5),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.white.withAlpha((0.8 * 255).toInt()),
                    child: ListTile(
                      leading: const Icon(
                        Icons.note,
                        color: Colors.deepPurple,
                      ),
                      title: Text(carte['nom']),
                      subtitle: Text(
                          'Créée : ${DateFormat('dd/MM/yyyy').format(carte['dateCreation'])}\nLimite : ${carte['dateLimite'] != null ? DateFormat('dd/MM/yyyy').format(carte['dateLimite']) : 'Non définie'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple,
                          ),
                          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editerCarte(carte)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _supprimerCarte(carte)),
                        ],
                      ),
                      onTap: () {
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