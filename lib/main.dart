import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/trello_auth.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TrelloAuthService _authService = TrelloAuthService();

  Future<void> _handleAuthentication() async {
    String? storedToken = await _authService.getStoredAccessToken();

    if (storedToken != null) {
      bool isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated) {
        print("Biometric Authentication Successful. Token: $storedToken");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        }
      } else {
        print("Biometric Authentication Failed.");
      }
    } else {
      await _authService.authenticateWithTrello();

      String? newToken = await _authService.getStoredAccessToken();
      if (newToken != null) {
        print("Authentication successful. Redirecting to Dashboard...");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trello Authentication")),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleAuthentication,
          child: Text("Login with Trello"),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Center(
        child: Text('Welcome to your Trello Dashboard!'),
      ),
    );
  }
}
