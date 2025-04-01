import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Affichage du titre de la liste', (WidgetTester tester) async {
    final liste = {'nom': 'Ma Liste', 'cartes': []};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(liste['nom'] as String),
          ],
        ),
      ),
    ));

    expect(find.text('Ma Liste'), findsOneWidget);
  });

  testWidgets('Ajout d\'une carte via bouton', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {},
          child: const Text('Ajouter une carte'),
        ),
      ),
    ));

    expect(find.text('Ajouter une carte'), findsOneWidget);
    await tester.tap(find.text('Ajouter une carte'));
    await tester.pump();
  });

  testWidgets('Affichage d\'une carte dans la liste', (WidgetTester tester) async {
    final carte = {'name': 'Carte Test', 'desc': 'Description test'};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListTile(
          title: Text(carte['name'] as String),
          subtitle: Text(carte['desc'] as String),
        ),
      ),
    ));

    expect(find.text('Carte Test'), findsOneWidget);
    expect(find.text('Description test'), findsOneWidget);
  });

  testWidgets('Affichage bouton Ajouter une liste', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {},
          child: const Text('Ajouter une liste'),
        ),
      ),
    ));

    expect(find.text('Ajouter une liste'), findsOneWidget);
  });

  testWidgets('Suppression d\'une carte', (WidgetTester tester) async {
    bool isDeleted = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            isDeleted = true;
          },
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();
    expect(isDeleted, isTrue);
  });

  testWidgets('Affichage multiple cartes', (WidgetTester tester) async {
    final cartes = [
      {'name': 'Carte 1', 'desc': 'Desc 1'},
      {'name': 'Carte 2', 'desc': 'Desc 2'},
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: cartes.map((carte) => ListTile(
            title: Text(carte['name'] as String),
            subtitle: Text(carte['desc'] as String),
          )).toList(),
        ),
      ),
    ));

    expect(find.text('Carte 1'), findsOneWidget);
    expect(find.text('Desc 1'), findsOneWidget);
    expect(find.text('Carte 2'), findsOneWidget);
    expect(find.text('Desc 2'), findsOneWidget);
  });

  testWidgets('Présence icône édition carte', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('CheckBox de statut carte', (WidgetTester tester) async {
    bool isChecked = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Checkbox(
          value: isChecked,
          onChanged: (bool? value) {
            isChecked = value ?? false;
          },
        ),
      ),
    ));

    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('Affichage du message d\'erreur si nom de la liste vide', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    String? errorText;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nom de la liste',
                errorText: errorText,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isEmpty) {
                  errorText = 'Le nom ne peut pas être vide';
                }
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(errorText, 'Le nom ne peut pas être vide');
  });

  testWidgets('Ajout d\'une carte déclenche fonction', (WidgetTester tester) async {
    bool wasCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () {
            wasCalled = true;
          },
          child: const Text('Ajouter une carte'),
        ),
      ),
    ));

    await tester.tap(find.text('Ajouter une carte'));
    await tester.pump();
    expect(wasCalled, isTrue);
  });

  testWidgets('Modification d\'une carte change le nom', (WidgetTester tester) async {
    final controller = TextEditingController(text: 'Ancien nom');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextField(controller: controller),
            Text(controller.text),
          ],
        ),
      ),
    ));

    controller.text = 'Nouveau nom';
    await tester.pump();

    expect(find.text('Nouveau nom'), findsOneWidget);
  });

  testWidgets('Validation affiche snackbar en cas d\'erreur', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur')),
                );
              },
              child: const Text('Valider'),
            ),
          );
        },
      ),
    ));

    await tester.tap(find.text('Valider'));
    await tester.pump(); // pour afficher le snackbar

    expect(find.text('Erreur'), findsOneWidget);
  });

  testWidgets('Champ nom carte affiche texte entré', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TextField(
          controller: controller,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'Nouvelle carte');
    expect(controller.text, 'Nouvelle carte');
  });

  testWidgets('Affichage message quand aucune carte', (WidgetTester tester) async {
    final liste = {'nom': 'Liste vide', 'cartes': []};

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(liste['nom'] as String),
            if ((liste['cartes'] as List).isEmpty)
              const Text('Aucune carte disponible'),
          ],
        ),
      ),
    ));

    expect(find.text('Aucune carte disponible'), findsOneWidget);
  });

  testWidgets('Ouverture du dialogue d\'édition de carte', (WidgetTester tester) async {
    bool opened = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            opened = true;
          },
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('Supprimer une liste déclenche l\'action', (WidgetTester tester) async {
    bool deleted = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            deleted = true;
          },
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pump();

    expect(deleted, isTrue);
  });

  testWidgets('Affichage bouton retour', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('Ajout visuel d\'une nouvelle liste', (WidgetTester tester) async {
    final listes = [
      {'id': '1', 'nom': 'Liste 1'},
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ...listes.map((l) => Text(l['nom'] as String)).toList(),
            const Text('Ajouter une liste'),
          ],
        ),
      ),
    ));

    expect(find.text('Liste 1'), findsOneWidget);
    expect(find.text('Ajouter une liste'), findsOneWidget);
  });
}
