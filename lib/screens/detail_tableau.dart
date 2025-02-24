import 'package:flutter/material.dart';

class DetailTableauScreen extends StatefulWidget {
  final Map<String, dynamic> tableau;

  const DetailTableauScreen({Key? key, required this.tableau}) : super(key: key);

  @override
  DetailTableauScreenState createState() => DetailTableauScreenState();
}

class DetailTableauScreenState extends State<DetailTableauScreen> {
  late List<Map<String, dynamic>> _taches;

  @override
  void initState() {
    super.initState();
    _taches = widget.tableau['taches']
        .map<Map<String, dynamic>>((tache) => {'nom': tache, 'fait': false})
        .toList();
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
                itemCount: _taches.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(_taches[index]['nom']),
                    value: _taches[index]['fait'],
                    onChanged: (bool? value) {
                      setState(() {
                        _taches[index]['fait'] = value ?? false;
                      });
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