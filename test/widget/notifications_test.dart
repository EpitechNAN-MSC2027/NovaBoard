import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/screens/notifications.dart';
import 'package:mockito/mockito.dart';
import 'package:nova_board/services/trello_service.dart';

class MockTrelloService extends Mock implements TrelloService {
  @override
  Future<List<dynamic>> getNotifications() => super.noSuchMethod(
    Invocation.method(#getNotifications, []),
    returnValue: Future.value([]),
    returnValueForMissingStub: Future.value([]),
  );
}

void main() {
  group('NotificationsScreen Widget Tests', () {
    testWidgets('Affiche "Aucune notification disponible" si la liste est vide', (WidgetTester tester) async {
      final mockService = MockTrelloService();
      when(mockService.getNotifications()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(trelloService: mockService),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Aucune notification disponible'), findsOneWidget);
    });

    testWidgets('Affiche une notification "Ajouté au tableau"', (WidgetTester tester) async {
      final mockService = MockTrelloService();
      when(mockService.getNotifications()).thenAnswer((_) async => [
        {
          'type': 'addedToBoard',
          'date': DateTime.now().toIso8601String(),
          'data': {
            'board': {'name': 'Projet Test'}
          }
        }
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(trelloService: mockService),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Ajouté au tableau'), findsOneWidget);
    });

    testWidgets('Affiche un message d\'erreur en cas d\'échec', (WidgetTester tester) async {
      final mockService = MockTrelloService();
      when(mockService.getNotifications()).thenThrow(Exception('Erreur'));

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(trelloService: mockService),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Erreur'), findsWidgets);
    });
  });
}
