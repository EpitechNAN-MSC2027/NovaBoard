import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/screens/navigation.dart';
import 'package:nova_board/services/trello_service.dart';

class FakeTrelloService extends TrelloService {
  FakeTrelloService() : super(apiKey: '', token: '');

  @override
  Future<bool> hasUnreadNotifications() async {
    return false;
  }
}

void main() {
  testWidgets('Navigation entre onglets fonctionne', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: NavigationScreen(trelloService: FakeTrelloService())));
    await tester.pumpAndSettle();

    expect(find.text('Workspaces'), findsWidgets);

    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Recherche'), findsWidgets);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('Déconnexion affiche un dialogue', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: NavigationScreen(trelloService: FakeTrelloService())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();

    expect(find.text('Déconnexion'), findsWidgets);
    expect(find.text('Êtes-vous sûr de vouloir vous déconnecter ?'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Déconnexion'), findsWidgets);
  });
}
