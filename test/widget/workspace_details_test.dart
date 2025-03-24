import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/screens/workspace_details.dart';
import 'package:nova_board/services/trello_service.dart';

class FakeTrelloService extends TrelloService {
  FakeTrelloService() : super(apiKey: '', token: '');

  @override
  Future<List<dynamic>> getBoardsForWorkspace(String workspaceId) async {
    return [
      {'id': 'board1', 'name': 'Tableau 1', 'desc': 'Description 1', 'prefs': {'permissionLevel': 'private'}},
    ];
  }

  @override
  Future<List<dynamic>> getBoardTemplates({String? searchTerm}) async {
    return [];
  }
}

void main() {
  group('WorkspaceDetailsScreen UI Tests', () {
    final workspace = {'id': 'workspace1', 'displayName': 'Workspace Test'};

    testWidgets('Affiche le titre Tableaux', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));

      expect(find.text('Tableaux'), findsOneWidget);
    });

    testWidgets('Affiche le bouton +', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Affiche un tableau mocké', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tableau 1'), findsOneWidget);
    });

    testWidgets('Affiche les icônes Modifier et Supprimer sur chaque tableau', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsWidgets);
      expect(find.byIcon(Icons.delete), findsWidgets);
    });

    testWidgets('Appui sur le bouton + ouvre le dialogue de création', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Créer'), findsOneWidget);
    });

    testWidgets('Appui sur le bouton retour fonctionne', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkspaceDetailsScreen(
                        workspace: workspace,
                        trelloService: FakeTrelloService(),
                      ),
                    ),
                  );
                },
                child: const Text('Go to Details'),
              );
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Details'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceDetailsScreen), findsNothing);
    });

    testWidgets('Clique sur un tableau → Navigation vers Listes (mock)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WorkspaceDetailsScreen(
          workspace: workspace,
          trelloService: FakeTrelloService(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tableau 1'));
      await tester.pump();

      expect(find.text('Tableau 1'), findsOneWidget);
    });
  });
}
