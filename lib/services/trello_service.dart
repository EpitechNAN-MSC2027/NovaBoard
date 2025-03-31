import 'dart:convert';
import 'dart:ffi';
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

  Future<Map<String, dynamic>> addMemberToWorkspace(String workspaceId, String email) async {
    final url = _buildUrl('organizations/$workspaceId/members');
    final response = await http.put(
      Uri.parse('$url?email=$email&key=$apiKey&token=$token'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de l\'ajout du membre : ${response.body}');
    }
  }

  Future<void> removeMemberFromWorkspace(String workspaceId, String memberId) async {
    final url = _buildUrl('organizations/$workspaceId/members/$memberId');
    final response = await http.delete(
      Uri.parse('$url?key=$apiKey&token=$token'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du membre : ${response.body}');
    }
  }

  Future<List<dynamic>> getMembersForWorkspace(String workspaceId) async {
    final url = _buildUrl('organizations/$workspaceId/members');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> members = jsonDecode(response.body);
        print("Membres du workspace récupérés : $members");
        return members;
      } else {
        throw Exception("Erreur lors de la récupération des membres : ${response.body}");
      }
    } catch (e) {
      print("Erreur réseau : $e");
      return [];
    }
  }

  Future<void> addMemberToCard(String cardId, String memberId) async {
    final url = _buildUrl('cards/$cardId/idMembers', {'value': memberId});
    final response = await http.post(url);
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'ajout du membre : ${response.body}');
    }
  }

  Future<void> removeMemberFromCard(String cardId, String memberId) async {
    final url = _buildUrl('cards/$cardId/idMembers/$memberId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du membre : ${response.body}');
    }
  }

  Future<void> updateBoardVisibility({
    required String boardId,
    required String visibility,
  }) async {
    final params = {
      'prefs/permissionLevel': visibility,
    };

    final url = _buildUrl('boards/$boardId');
    final response = await http.put(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode != 200) {
      throw Exception('Failed to update board visibility: ${response.body}');
    }
  }

  // ============ WORKSPACES (ORGANIZATIONS) OPERATIONS ============

  /// Get all workspaces for the current member
  Future<List<dynamic>> getWorkspaces() async {
    final url = _buildUrl('members/me/organizations');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workspaces (Status: ${response.statusCode})');
    }
  }

  /// Get a specific workspace by ID
  Future<Map<String, dynamic>> getWorkspace(String workspaceId) async {
    final url = _buildUrl('organizations/$workspaceId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workspace $workspaceId');
    }
  }

  /// Create a new workspace
  Future<Map<String, dynamic>> createWorkspace({
    required String name,
    String? displayName,
    String? desc,
    String? website,
  }) async {
    final params = {
      'name': name,
      if (displayName != null) 'displayName': displayName,
      if (desc != null) 'desc': desc,
      if (website != null) 'website': website,
    };

    final url = _buildUrl('organizations');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create workspace: ${response.body}');
    }
  }

  /// Update a workspace
  Future<Map<String, dynamic>> updateWorkspace({
    required String workspaceId,
    String? name,
    String? displayName,
    String? desc,
    String? website,
  }) async {
    final params = {
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (desc != null) 'desc': desc,
      if (website != null) 'website': website,
    };

    final url = _buildUrl('organizations/$workspaceId');
    final response = await http.put(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update workspace $workspaceId: ${response.body}');
    }
  }

  /// Delete a workspace
  Future<bool> deleteWorkspace(String workspaceId) async {
    final url = _buildUrl('organizations/$workspaceId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete workspace $workspaceId: ${response.body}');
    }
  }

  // ============ BOARD OPERATIONS ============

  /// Get all boards for the current member
  Future<List<dynamic>> getBoards() async {
    final url = _buildUrl('members/me/boards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load boards (Status: ${response.statusCode})');
    }
  }

  /// Get boards for a specific workspace
  Future<List<dynamic>> getBoardsForWorkspace(String workspaceId) async {
    final url = _buildUrl('organizations/$workspaceId/boards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load boards for workspace $workspaceId');
    }
  }

  /// Get a specific board by ID
  Future<Map<String, dynamic>> getBoard(String boardId) async {
    final url = _buildUrl('boards/$boardId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load board $boardId');
    }
  }

  /// Get available public board templates
  Future<List<dynamic>> getBoardTemplates({String? searchTerm}) async {
    // Use the search endpoint to find public templates
    final url = _buildUrl('boards/templates/gallery', {
      'fields': 'name,desc,prefs',
      if (searchTerm != null && searchTerm.isNotEmpty) 'search': searchTerm,
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Extract just the boards from the search results
      return data ?? [];
    } else {
      throw Exception('Failed to load board templates (Status: ${response.statusCode})');
    }
  }


  /// Create a new board
  Future<Map<String, dynamic>> createBoard({
    required String name,
    String? desc,
    String? idOrganization,
    String? defaultLists = "true",
    String? prefs,
  }) async {
    final params = {
      'name': name,
      if (desc != null) 'desc': desc,
      if (idOrganization != null) 'idOrganization': idOrganization,
      'defaultLists': defaultLists ?? "true",
      if (prefs != null) 'prefs': prefs,
    };

    final url = _buildUrl('boards');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create board: ${response.body}');
    }
  }

  /// Create a new board from a template
  Future<Map<String, dynamic>> createBoardFromTemplate({
    required String name,
    required String templateId,
    String? idOrganization,
    String? prefs,
  }) async {
    final params = {
      'name': name,
      'idBoardSource': templateId,
      if (idOrganization != null) 'idOrganization': idOrganization,
      if (prefs != null) 'prefs': prefs,
    };

    final url = _buildUrl('boards');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create board from template: ${response.body}');
    }
  }

  /// Update a board
  Future<Map<String, dynamic>> updateBoard({
    required String boardId,
    String? name,
    String? desc,
    String? closed,
    String? prefs,
    String? idOrganization,
  }) async {
    final params = {
      if (name != null) 'name': name,
      if (desc != null) 'desc': desc,
      if (closed != null) 'closed': closed,
      if (prefs != null) 'prefs': prefs,
      if (idOrganization != null) 'idOrganization': idOrganization,
    };

    final url = _buildUrl('boards/$boardId');
    final response = await http.put(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update board $boardId: ${response.body}');
    }
  }

  /// Delete a board (technically archiving/closing it, as Trello doesn't truly delete)
  Future<bool> deleteBoard(String boardId) async {
    // In Trello, boards are "closed" rather than deleted
    final url = _buildUrl('boards/$boardId', {'closed': 'true'});
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete (close) board $boardId: ${response.body}');
    }
  }

  // ============ LIST OPERATIONS ============

  /// Get all lists for a specific board
  Future<List<dynamic>> getListsForBoard(String boardId, {bool includeArchived = false}) async {
    final Map<String, String> params = includeArchived ? {} : {'filter': 'open'};
    final url = _buildUrl('boards/$boardId/lists', params);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lists for board $boardId');
    }
  }

  /// Get a specific list by ID
  Future<Map<String, dynamic>> getList(String listId) async {
    final url = _buildUrl('lists/$listId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load list $listId');
    }
  }

  /// Create a new list on a board
  Future<Map<String, dynamic>> createList({
    required String boardId,
    required String name,
    String? pos,
  }) async {
    final params = {
      'idBoard': boardId,
      'name': name,
      if (pos != null) 'pos': pos,
    };

    final url = _buildUrl('lists');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create list on board $boardId: ${response.body}');
    }
  }

  /// Update a list
  Future<Map<String, dynamic>> updateList({
    required String listId,
    String? name,
    String? closed,
    String? pos,
    String? idBoard,
  }) async {
    final params = {
      if (name != null) 'name': name,
      if (closed != null) 'closed': closed,
      if (pos != null) 'pos': pos,
      if (idBoard != null) 'idBoard': idBoard,
    };

    final url = _buildUrl('lists/$listId');
    final response = await http.put(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update list $listId: ${response.body}');
    }
  }

  /// Archive a list (Trello doesn't allow permanent deletion of lists)
  Future<bool> archiveList(String listId) async {
    final url = _buildUrl('lists/$listId/closed', {'value': 'true'});
    final response = await http.put(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to archive list $listId: ${response.body}');
    }
  }

  // ============ CARD OPERATIONS ============

  /// Get all cards on a list
  Future<List<dynamic>> getCardsForList(String listId) async {
    final url = _buildUrl('lists/$listId/cards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load cards for list $listId');
    }
  }

  /// Get all cards on a board
  Future<List<dynamic>> getCardsForBoard(String boardId) async {
    final url = _buildUrl('boards/$boardId/cards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load cards for board $boardId');
    }
  }

  /// Get a specific card by ID
  Future<Map<String, dynamic>> getCard(String cardId) async {
    final url = _buildUrl('cards/$cardId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load card $cardId');
    }
  }

  /// Create a new card on a list
  Future<Map<String, dynamic>> createCard({
    required String listId,
    required String name,
    String? desc,
    String? pos,
    String? due,
    List<String>? idMembers,
    List<String>? idLabels,
    String? urlSource,
  }) async {
    final params = {
      'idList': listId,
      'name': name,
      if (desc != null) 'desc': desc,
      if (pos != null) 'pos': pos,
      if (due != null) 'due': due,
    };

    // Add members if specified
    if (idMembers != null && idMembers.isNotEmpty) {
      for (int i = 0; i < idMembers.length; i++) {
        params['idMembers[$i]'] = idMembers[i];
      }
    }

    // Add labels if specified
    if (idLabels != null && idLabels.isNotEmpty) {
      for (int i = 0; i < idLabels.length; i++) {
        params['idLabels[$i]'] = idLabels[i];
      }
    }

    // Add URL source if specified
    if (urlSource != null) {
      params['urlSource'] = urlSource;
    }

    final url = _buildUrl('cards');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create card on list $listId: ${response.body}');
    }
  }

  /// Update a card
  Future<Map<String, dynamic>> updateCard({
    required String cardId,
    String? name,
    String? desc,
    String? closed,
    String? idList,
    String? idMembers,
    String? idLabels,
    String? pos,
    String? due,
    String? dueComplete,
  }) async {
    final params = {
      if (name != null) 'name': name,
      if (desc != null) 'desc': desc,
      if (closed != null) 'closed': closed,
      if (idList != null) 'idList': idList,
      if (idMembers != null) 'idMembers': idMembers,
      if (idLabels != null) 'idLabels': idLabels,
      if (pos != null) 'pos': pos,
      if (due != null) 'due': due,
      if (dueComplete != null) 'dueComplete': dueComplete,
    };

    final url = _buildUrl('cards/$cardId');
    final response = await http.put(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update card $cardId: ${response.body}');
    }
  }

  /// Delete a card
  Future<bool> deleteCard(String cardId) async {
    final url = _buildUrl('cards/$cardId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete card $cardId: ${response.body}');
    }
  }

  // ============ ADDITIONAL OPERATIONS ============

  /// Add a comment to a card
  Future<Map<String, dynamic>> addCommentToCard({
    required String cardId,
    required String text,
  }) async {
    final url = _buildUrl('cards/$cardId/actions/comments', {'text': text});
    final response = await http.post(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add comment to card $cardId: ${response.body}');
    }
  }

  /// Get labels for a board
  Future<List<dynamic>> getLabelsForBoard(String boardId) async {
    final url = _buildUrl('boards/$boardId/labels');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load labels for board $boardId');
    }
  }

  /// Create a label for a board
  Future<Map<String, dynamic>> createLabel({
    required String boardId,
    required String name,
    String? color,
  }) async {
    final params = {
      'name': name,
      'idBoard': boardId,
      if (color != null) 'color': color,
    };

    final url = _buildUrl('labels');
    final response = await http.post(url.replace(queryParameters: {...url.queryParameters, ...params}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create label on board $boardId: ${response.body}');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final url = _buildUrl('members/me/notifications');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> searchTrello({String? searchTerm}) async {
    final url = _buildUrl('search', {
      if (searchTerm != null) 'query': searchTerm,
    });
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load search results: ${response.body}');
    }
  }
}