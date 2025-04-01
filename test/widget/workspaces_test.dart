import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/screens/workspaces.dart';
import 'package:nova_board/services/trello_service.dart';

class FakeTrelloService extends TrelloService {
  FakeTrelloService() : super(apiKey: '', token: '');

  @override
  Future<List<dynamic>> getWorkspaces() async {
    return [
      {'id': 'ws1', 'name': 'Workspace 1', 'desc': 'Description 1'},
      {'id': 'ws2', 'name': 'Workspace 2', 'desc': 'Description 2'},
    ];
  }
}

void main() {
  testWidgets('Affiche la liste des workspaces', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkspacesScreen(trelloService: FakeTrelloService()),
    ));
    await tester.pumpAndSettle();

    final listTiles = find.byType(ListTile);
    expect(listTiles, findsNWidgets(2));

    expect(find.text('No name'), findsNWidgets(2));

    expect(find.text('Description 1'), findsOneWidget);
    expect(find.text('Description 2'), findsOneWidget);
  });

  testWidgets('Bouton + ouvre le dialogue de création', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkspacesScreen(trelloService: FakeTrelloService()),
    ));
    await tester.pumpAndSettle();

    tester.allWidgets.forEach((widget) => print(widget));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Create new workspace'), findsOneWidget);
    expect(find.text('Name of workspace'), findsOneWidget);
    expect(find.text('Description of workspace'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Taper sur un workspace navigue vers les détails', (WidgetTester tester) async {
    bool navigated = false;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return WorkspacesScreen(trelloService: FakeTrelloService(), onNavigate: () {
          navigated = true;
        });
      }),
    ));
    await tester.pumpAndSettle();

    tester.allWidgets.forEach((widget) => print(widget));

    await tester.tap(find.text('No name').first);
    await tester.pumpAndSettle();

    expect(navigated, true);
  });

  testWidgets('Menu 3 points affiche Modifier et Supprimer', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: WorkspacesScreen(trelloService: FakeTrelloService()),
    ));
    await tester.pumpAndSettle();

    tester.allWidgets.forEach((widget) => print(widget));

    final menuIcon = find.byIcon(Icons.more_vert).first;
    expect(menuIcon, findsOneWidget);

    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    expect(find.text('✏️ Modifier'), findsOneWidget);
    expect(find.text('🗑️ Supprimer'), findsOneWidget);
    expect(find.text('👥 Gérer les membres'), findsOneWidget);
  });
}
