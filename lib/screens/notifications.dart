import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/trello_auth.dart';
import '../services/trello_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final TrelloService? trelloService;

  const NotificationsScreen({Key? key, this.trelloService}) : super(key: key);

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  TrelloService? _trelloService;
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initTrelloService();
  }

  Future<void> _initTrelloService() async {
    if (widget.trelloService != null) {
      _trelloService = widget.trelloService;
      await _loadNotifications();
      return;
    }

    try {
      final trelloAuthService = TrelloAuthService();
      final token = await trelloAuthService.getStoredAccessToken() ?? '';

      if (token.isEmpty) {
        setState(() {
          _errorMessage = "No token found, please login again.";
          _isLoading = false;
        });
        return;
      }
      _trelloService = TrelloService(
        apiKey: dotenv.env['TRELLO_API_KEY'] ?? '',
        token: token,
      );

      await _loadNotifications();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Trello: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      if (_trelloService == null) {
        setState(() {
          _errorMessage = 'TrelloService is not initialized';
          _isLoading = false;
        });
        return;
      }
      final notifications = await _trelloService!.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _notifications.isEmpty
                    ? const Center(child: Text("Aucune notification disponible"))
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final type = notif['type'] ?? 'Type inconnu';
                          final date = notif['date'] != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(notif['date']))
                              : 'Date inconnue';

                          String message = '';
                          if (type == 'addedToBoard') {
                            message = "Ajouté au tableau : ${notif['data']?['board']?['name'] ?? 'inconnu'}";
                          } else if (type == 'addedToCard') {
                            message = "Ajouté à la carte : ${notif['data']?['card']?['name'] ?? 'inconnu'}";
                          } else if (type == 'commentCard') {
                            message = "Commentaire sur carte : ${notif['data']?['card']?['name'] ?? 'inconnu'}";
                          } else if (type == 'updateCard') {
                            message = "Carte mise à jour : ${notif['data']?['card']?['name'] ?? 'inconnu'}";
                          } else {
                            message = "Notification : $type";
                          }

                          return Card(
                            color: Colors.white.withOpacity(0.8),
                            child: ListTile(
                              leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                              title: Text(message),
                              subtitle: Text(date),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
