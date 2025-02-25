import 'dart:convert';
import 'package:http/http.dart' as http;

class TrelloService {
  final String apiKey;
  final String token;
  final String baseUrl = 'https://api.trello.com/1/';

  TrelloService({required this.apiKey, required this.token});

  /// Builds a URL with the necessary authentication query parameters.
  Uri _buildUrl(String path, [Map<String, String>? params]) {
    final queryParameters = {
      'key': apiKey,
      'token': token,
    };

    if (params != null) {
      queryParameters.addAll(params);
    }

    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  /// Example: Get all boards for the current member.
  Future<List<dynamic>> getBoards() async {
    final url = _buildUrl('members/me/boards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load boards (Status: ${response.statusCode})');
    }
  }

  /// Example: Get all lists for a specific board.
  Future<List<dynamic>> getListsForBoard(String boardId) async {
    final url = _buildUrl('boards/$boardId/lists');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lists for board $boardId');
    }
  }

  /// Example: Create a new card on a list.
  Future<Map<String, dynamic>> createCard({
    required String listId,
    required String name,
    required String desc,
  }) async {
    final url = _buildUrl('cards', {
      'idList': listId,
      'name': name,
      'desc': desc,
    });
    final response = await http.post(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create card on list $listId');
    }
  }
}