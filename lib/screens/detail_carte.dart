import 'package:flutter/material.dart';

class DetailCarteScreen extends StatelessWidget {
  final Map<String, dynamic> carte;

  const DetailCarteScreen({Key? key, required this.carte}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(carte['nom']),
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
              carte['description'].isNotEmpty
                  ? carte['description']
                  : 'Aucune description',
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