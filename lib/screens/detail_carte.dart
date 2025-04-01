import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailCarteScreen extends StatefulWidget {
  final Map<String, dynamic> carte;

  const DetailCarteScreen({Key? key, required this.carte}) : super(key: key);

  @override
  DetailCarteScreenState createState() => DetailCarteScreenState();
}

class DetailCarteScreenState extends State<DetailCarteScreen> {
  Map<String, dynamic>? _updatedCarte;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initTrelloService();
  }

  void _initTrelloService() {
    _loadCarteDetail();
  }

  void _loadCarteDetail() {
    setState(() {
      _updatedCarte = widget.carte;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_updatedCarte == null && _errorMessage == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.carte['name']),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.carte['name']),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_updatedCarte!['name']),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _updatedCarte!['desc'] != null && _updatedCarte!['desc'].isNotEmpty
                  ? _updatedCarte!['desc']
                  : 'Aucune description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Date limite :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _updatedCarte!['due'] != null
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_updatedCarte!['due']))
                  : 'Non définie',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Statut :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _updatedCarte!['dueComplete'] == true ? 'Terminé' : 'En cours',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}