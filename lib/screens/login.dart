import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
                  () {
                Navigator.pushReplacementNamed(context, '/navigation');
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              context,
              'Sign Up',
              'lib/assets/LogoTrello.png',
                  () {
                Navigator.pushReplacementNamed(context, '/navigation');
              },
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