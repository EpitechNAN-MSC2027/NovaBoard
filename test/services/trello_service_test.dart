import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/services/trello_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('TrelloService Tests', () {
    late TrelloService trelloService;

    setUp(() {
      trelloService = TrelloService(apiKey: 'fakeKey', token: 'fakeToken');
    });

    test('getBoardsForWorkspace returns list of boards', () async {
      trelloService.client = MockClient((request) async {
        expect(request.url.toString(), contains('/organizations/workspaceId/boards'));
        return http.Response(jsonEncode([
          {'id': 'board1', 'name': 'Test Board'}
        ]), 200);
      });

      final boards = await trelloService.getBoardsForWorkspace('workspaceId');
      expect(boards, isA<List>());
      expect(boards.first['name'], 'Test Board');
    });

    test('getCard returns card details', () async {
      trelloService.client = MockClient((request) async {
        expect(request.url.toString(), contains('/cards/cardId'));
        return http.Response(jsonEncode({'id': 'cardId', 'name': 'Test Card'}), 200);
      });

      final card = await trelloService.getCard('cardId');
      expect(card['name'], 'Test Card');
    });

    test('hasUnreadNotifications returns true when unread exists', () async {
      trelloService.client = MockClient((request) async {
        return http.Response(jsonEncode([
          {'unread': true}
        ]), 200);
      });

      final result = await trelloService.hasUnreadNotifications();
      expect(result, isTrue);
    });

    test('createCard creates a new card', () async {
      trelloService.client = MockClient((request) async {
        expect(request.url.toString(), contains('/cards'));
        expect(request.method, equals('POST'));
        return http.Response(jsonEncode({'id': 'card1', 'name': 'New Card'}), 200);
      });

      final card = await trelloService.createCard(
        listId: 'listId',
        name: 'New Card',
        desc: 'Description',
      );
      expect(card['name'], 'New Card');
    });

    test('updateCard updates card details', () async {
      trelloService.client = MockClient((request) async {
        expect(request.url.toString(), contains('/cards/cardId'));
        expect(request.method, equals('PUT'));
        return http.Response(jsonEncode({'id': 'cardId', 'name': 'Updated Card'}), 200);
      });

      final card = await trelloService.updateCard(
        cardId: 'cardId',
        name: 'Updated Card',
        desc: 'Updated Description',
      );
      expect(card['name'], 'Updated Card');
    });

    test('getBoardsForWorkspace throws on failure', () async {
      trelloService.client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async => await trelloService.getBoardsForWorkspace('workspaceId'),
        throwsException);
    });

    test('getCard throws on failure', () async {
      trelloService.client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async => await trelloService.getCard('cardId'), throwsException);
    });

    test('createCard throws on failure', () async {
      trelloService.client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async => await trelloService.createCard(
        listId: 'listId',
        name: 'New Card',
        desc: 'Description',
      ), throwsException);
    });

    test('updateCard throws on failure', () async {
      trelloService.client = MockClient((request) async {
        return http.Response('Error', 400);
      });

      expect(() async => await trelloService.updateCard(
        cardId: 'cardId',
        name: 'Updated Card',
        desc: 'Updated Description',
      ), throwsException);
    });

    test('hasUnreadNotifications returns false when none are unread', () async {
      trelloService.client = MockClient((request) async {
        return http.Response(jsonEncode([
          {'unread': false}
        ]), 200);
      });

      final result = await trelloService.hasUnreadNotifications();
      expect(result, isFalse);
    });
  });
}
