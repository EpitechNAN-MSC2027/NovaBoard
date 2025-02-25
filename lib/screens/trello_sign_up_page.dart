import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrelloSignUpPage extends StatefulWidget {
  @override
  _TrelloSignUpPageState createState() => _TrelloSignUpPageState();
}

class _TrelloSignUpPageState extends State<TrelloSignUpPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://trello.com/signup'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up for Trello"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // Close WebView and return to LoginScreen
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}