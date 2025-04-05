import 'package:flutter/material.dart';
import '../services/trello_auth.dart';
import 'pin_setup_screen.dart';
import 'pin_entry_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TrelloAuthService _authService = TrelloAuthService();

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    String? storedToken = await _authService.getStoredAccessToken();
    if (storedToken != null) {
      bool isPinSetup = await _authService.isPinSetup();

      if (isPinSetup) {
        // If PIN is set up, go directly to PIN entry
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => const PinEntryScreen(),
            ),
          );
          return;
        }
      } else {
        // Token exists but no PIN setup yet
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => const PinSetupScreen(),
            ),
          );
          return;
        }
      }
    }
    // If no token or PIN, stay on login screen
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await _authService.authenticateWithTrello();

      if (mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
      }

      String? storedToken = await _authService.getStoredAccessToken();
      if (storedToken != null && mounted) {

        // Navigate to PIN setup screen for first-time users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PinSetupScreen()),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context).pop(); // Close the loading dialog if open
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/LogoSombre.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 0),
            const Text(
              'NovaBoard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            _buildButton(
              context,
              'Sign In',
              'lib/assets/LogoTrello.png',
              () => _handleSignIn(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, String imagePath, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          imagePath,
          width: 24,
          height: 24,
        ),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}