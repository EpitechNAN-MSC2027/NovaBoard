import 'package:flutter/material.dart';
import 'workspace_details.dart';

class WorkspacesScreen extends StatefulWidget {
  const WorkspacesScreen({Key? key}) : super(key: key);

  @override
  WorkspacesScreenState createState() => WorkspacesScreenState();
}

class WorkspacesScreenState extends State<WorkspacesScreen> {
  final List<Map<String, dynamic>> _workspaces = [];
  final TextEditingController _workspaceNameController = TextEditingController();
  final TextEditingController _workspaceDescriptionController = TextEditingController();

  void _ajouterWorkspace() {
    _workspaceNameController.clear();
    _workspaceDescriptionController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Créer un nouvel espace de travail'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _workspaceNameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'espace de travail'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _workspaceDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description de l\'espace de travail'),
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
                if (_workspaceNameController.text.isNotEmpty &&
                    _workspaceDescriptionController.text.isNotEmpty) {
                  setState(() {
                    _workspaces.add({
                      'nom': _workspaceNameController.text,
                      'description': _workspaceDescriptionController.text,
                      'tableaux': []
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
                    'Espaces de travail',
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
          Expanded(
            child: ListView.builder(
              itemCount: _workspaces.length,
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
                        Icons.workspaces,
                        color: Colors.deepPurple,
                      ),
                      title: Text(_workspaces[index]['nom']),
                      subtitle: Text(_workspaces[index]['description']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkspaceDetailsScreen(workspace: _workspaces[index]),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    )]));
  }
}