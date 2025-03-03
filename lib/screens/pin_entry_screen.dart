import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/trello_auth.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({Key? key}) : super(key: key);

  @override
  _PinEntryScreenState createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final storage = const FlutterSecureStorage();
  final TrelloAuthService _authService = TrelloAuthService();
  String _pin = '';
  String _errorMessage = '';
  int _attempts = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool biometricsAvailable = await _authService.isBiometricsAvailable();
    if (biometricsAvailable) {
      // Slight delay to ensure the screen is fully built
      Future.delayed(Duration(milliseconds: 300), () async {
        bool isAuthenticated = await _authService.authenticateWithBiometrics();
        if (isAuthenticated && mounted) {
          Navigator.pushReplacementNamed(context, '/navigation');
        }
        // If biometric auth fails, user can still use PIN
      });
    }
  }

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = '';
      });

      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _deleteDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _validatePin() async {
    // Retrieve the stored PIN
    String? storedPin = await storage.read(key: 'user_pin');

    if (storedPin == _pin) {
      // PIN is correct, navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    } else {
      // Increment attempts counter
      _attempts++;

      setState(() {
        if (_attempts >= _maxAttempts) {
          _errorMessage = 'Too many incorrect attempts. Please sign in again.';
          // Reset the stored token to force a re-login with Trello
          storage.delete(key: 'trello_access_token');

          // Navigate back to login screen after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          _errorMessage = 'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
          _pin = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enter PIN'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<bool>(
        future: _authService.isBiometricsAvailable(),
        builder: (context, snapshot) {
          final biometricsAvailable = snapshot.data ?? false;

          return Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Enter your PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length ? Colors.deepPurple : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              _buildNumPad(biometricsAvailable),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNumPad(bool biometricsAvailable) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('1'),
            _buildDigitButton('2'),
            _buildDigitButton('3'),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('4'),
            _buildDigitButton('5'),
            _buildDigitButton('6'),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDigitButton('7'),
            _buildDigitButton('8'),
            _buildDigitButton('9'),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80),
            _buildDigitButton('0'),
            SizedBox(
              width: 80,
              height: 80,
              child: _pin.isEmpty && biometricsAvailable
                  ? IconButton(
                      icon: const Icon(Icons.fingerprint, size: 24),
                      onPressed: () async {
                        bool isAuthenticated = await _authService.authenticateWithBiometrics();
                        if (isAuthenticated && mounted) {
                          Navigator.pushReplacementNamed(context, '/navigation');
                        }
                      },
                    )
                  : IconButton(
                    icon: const Icon(Icons.backspace, size: 24),
                    onPressed: _deleteDigit,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: () => _addDigit(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}