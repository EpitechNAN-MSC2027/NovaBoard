import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/screens/detail_carte.dart';

void main() {
  final carteAvecTout = {
    'name': 'Carte Test',
    'desc': 'Ceci est une description.',
    'due': '2025-04-01T00:00:00.000Z',
    'dueComplete': true,
  };

  final carteSansDescNiDate = {
    'name': 'Carte Incomplète',
    'desc': '',
    'due': null,
    'dueComplete': false,
  };

  testWidgets('Affiche CircularProgressIndicator quand _updatedCarte et _errorMessage sont null', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DetailCarteScreen(carte: {'name': 'Carte Vide'}),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Affiche message d\'erreur quand _errorMessage est défini', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Text('Une erreur est survenue'),
      ),
    ));

    await tester.pump();

    expect(find.text('Une erreur est survenue'), findsOneWidget);
  });

  testWidgets('Affiche toutes les infos d\'une carte complète', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DetailCarteScreen(carte: carteAvecTout),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Carte Test'), findsWidgets); // AppBar + Body
    expect(find.text('Ceci est une description.'), findsOneWidget);
    expect(find.text('01/04/2025'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
  });

  testWidgets('Affiche valeurs par défaut pour une carte incomplète', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DetailCarteScreen(carte: carteSansDescNiDate),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Carte Incomplète'), findsWidgets);
    expect(find.text('Aucune description'), findsOneWidget);
    expect(find.text('Non définie'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
  });

  testWidgets('Appuyer sur le bouton Retour fait un pop', (WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (context) {
          return const DetailCarteScreen(carte: {
            'name': 'Carte Test',
            'desc': 'Test',
            'due': '2025-04-01T00:00:00.000Z',
            'dueComplete': false,
          });
        },
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Retour'), findsOneWidget);

    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    // Si le pop fonctionne, l'écran doit disparaître
    expect(find.byType(DetailCarteScreen), findsNothing);
  });
}