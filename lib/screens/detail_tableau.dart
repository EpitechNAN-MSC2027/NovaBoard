import 'package:flutter/material.dart';

class DetailTableauScreen extends StatefulWidget {
  final Map<String, dynamic> tableau;

  const DetailTableauScreen({Key? key, required this.tableau}) : super(key: key);

  @override
  DetailTableauScreenState createState() => DetailTableauScreenState();
}

class DetailTableauScreenState extends State<DetailTableauScreen> {
  late List<Map<String, dynamic>> _listes;

  @override
  void initState() {
    super.initState();
    _listes = (widget.tableau['listes'] ?? []).map<Map<String, dynamic>>((liste) {
      if (liste is String) {
        return {'nom': liste, 'cartes': []};
      } else if (liste is Map<String, dynamic>) {
        return {
          'nom': liste['nom'] ?? 'Liste sans nom',
          'cartes': liste['cartes'] ?? []
        };
      } else {
        return {'nom': 'Liste inconnue', 'cartes': []};
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau : ${widget.tableau['nom']}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _listes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_listes[index]['nom']),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                    onTap: () {
                      // Ici, on pourra ouvrir les cartes de la liste
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}