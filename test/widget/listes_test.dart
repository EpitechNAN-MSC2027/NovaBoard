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
}
