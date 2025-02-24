import 'package:flutter/material.dart';
import 'detail_tableau.dart';

class TableauScreen extends StatefulWidget {
  const TableauScreen({Key? key}) : super(key: key);

  @override
  TableauScreenState createState() => TableauScreenState();
}

class TableauScreenState extends State<TableauScreen> {
  final List<Map<String, dynamic>> _tableaux = [];
  final TextEditingController _tableauController = TextEditingController();
  final TextEditingController _tacheController = TextEditingController();
  List<String> _tachesTemp = [];

  void _ajouterTableau() {
    _tachesTemp = [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text('Créer un nouveau tableau'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tableauController,
                    decoration: const InputDecoration(labelText: 'Nom du tableau'),
                  ),
                  TextField(
                    controller: _tacheController,
                    decoration: const InputDecoration(labelText: 'Ajouter une tâche'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_tacheController.text.isNotEmpty) {
                        setStateModal(() {
                          _tachesTemp.add(_tacheController.text);
                          _tacheController.clear();
                        });
                      }
                    },
                    child: const Text('Ajouter une tâche'),
                  ),
                  const SizedBox(height: 10),
                  ..._tachesTemp.map((tache) => ListTile(
                    title: Text(tache),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setStateModal(() {
                          _tachesTemp.remove(tache);
                        });
                      },
                    ),
                  )),
                ],
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
                    if (_tableauController.text.isNotEmpty && _tachesTemp.isNotEmpty) {
                      setState(() {
                        _tableaux.add({
                          'nom': _tableauController.text,
                          'taches': List<String>.from(_tachesTemp)
                        });
                        _tableauController.clear();
                        _tacheController.clear();
                      });
                      Navigator.of(context).pop(); // Fermer la fenêtre modale après l'ajout
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

  void _afficherDetailsTableau(Map<String, dynamic> tableau) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailTableauScreen(tableau: tableau),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/FondApp.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'lib/assets/LogoSombre.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
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
                itemCount: _tableaux.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      child: ListTile(
                        leading: const Icon(
                          Icons.list,
                          color: Colors.deepPurple,
                        ),
                        title: Text(_tableaux[index]['nom']),
                        subtitle: Text('Tâches: ${_tableaux[index]['taches'].length}'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.deepPurple,
                        ),
                        onTap: () {
                          _afficherDetailsTableau(_tableaux[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}