import 'package:flutter/material.dart';
import 'navigation.dart';

class WorkspaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> workspace;

  const WorkspaceDetailsScreen({Key? key, required this.workspace}) : super(key: key);

  @override
  WorkspaceDetailsScreenState createState() => WorkspaceDetailsScreenState();
}

class WorkspaceDetailsScreenState extends State<WorkspaceDetailsScreen> {
  final TextEditingController _tableauNameController = TextEditingController();
  final TextEditingController _tableauDescriptionController = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();
  List<String> _listesTemp = [];

  void _ajouterTableau() {
    _tableauNameController.clear();
    _tableauDescriptionController.clear();
    _listesTemp = [];
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
                            _listesTemp.add(_listNameController.text);
                            _listNameController.clear();
                          });
                        }
                      },
                      child: const Text('Ajouter une liste'),
                    ),
                    const SizedBox(height: 10),
                    ..._listesTemp.map((tache) => ListTile(
                      title: Text(tache),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateModal(() {
                            _listesTemp.remove(tache);
                          });
                        },
                      ),
                    )),
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
                    if (_tableauNameController.text.isNotEmpty &&
                        _tableauDescriptionController.text.isNotEmpty) {
                      setState(() {
                        widget.workspace['tableaux'].add({
                          'nom': _tableauNameController.text,
                          'description': _tableauDescriptionController.text,
                          'liste': List<String>.from(_listesTemp)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace['nom']),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.workspace['description'],
                style: const TextStyle(fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.deepPurple, size: 30),
            onPressed: _ajouterTableau,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.workspace['tableaux'].length,
              itemBuilder: (context, index) {
                final tableau = widget.workspace['tableaux'][index];
                return ListTile(
                  title: Text(tableau['nom']),
                  subtitle: Text('liste: ${tableau['liste'].length}'),
                  onTap: () {
                    print("Tableau cliqué : ${tableau['nom']}");
                    final navigationState = navigationKey.currentState;
                    if (navigationState != null) {
                      print("NavigationState détecté !");
                      navigationState.setSelectedTableau(widget.workspace, tableau);
                      navigationState.setSelectedIndex(1);
                      navigationState.setState(() {});
                    } else {
                      print("NavigationState est NULL !");
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}