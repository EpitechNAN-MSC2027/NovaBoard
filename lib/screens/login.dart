import 'package:flutter/material.dart';
import '../services/trello_auth.dart';

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
    _checkBiometricAuth();
  }

  Future<void> _checkBiometricAuth() async {
    String? storedToken = await _authService.getStoredAccessToken();
    if (storedToken != null) {
      bool isAuthenticated = await _authService.authenticateWithBiometrics();
      if (isAuthenticated && mounted) {
        print("Biometric Authentication Successful. Redirecting...");
        Navigator.pushReplacementNamed(context, '/navigation');
      } else {
        print("Biometric Authentication Failed or Canceled.");
      }
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      await _checkBiometricAuth(); // Try biometric auth first

      String? storedToken = await _authService.getStoredAccessToken();
      if (storedToken == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        await _authService.authenticateWithTrello();

        if (mounted) Navigator.of(context).pop();

        storedToken = await _authService.getStoredAccessToken();
      }

      if (storedToken != null && mounted) {
        print("Authentication successful. Redirecting...");
        Navigator.pushReplacementNamed(context, '/navigation');
      } else {
        print("Authentication Failed.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      print("Authentication Error: $e");
      if (mounted) {
        Navigator.of(context).pop(false);

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