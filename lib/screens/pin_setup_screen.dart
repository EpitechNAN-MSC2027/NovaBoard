import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final storage = const FlutterSecureStorage();
  String _pin = '';
  String _confirmPin = '';
  bool _isPinConfirmation = false;
  String _errorMessage = '';

  void _addDigit(String digit) {
    setState(() {
      if (!_isPinConfirmation) {
        if (_pin.length < 4) {
          _pin += digit;
        }
        if (_pin.length == 4) {
          _isPinConfirmation = true;
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
        }
        if (_confirmPin.length == 4) {
          _validatePins();
        }
      }
    });
  }

  void _deleteDigit() {
    setState(() {
      if (!_isPinConfirmation) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Allow going back to first PIN entry if confirmation is empty
          _isPinConfirmation = false;
        }
      }
      _errorMessage = '';
    });
  }

  void _validatePins() async {
    if (_pin == _confirmPin) {
      // Store the PIN securely
      await storage.write(key: 'user_pin', value: _pin);

      // Set flag to indicate PIN has been set up
      await storage.write(key: 'pin_setup_complete', value: 'true');

      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Set up PIN'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            !_isPinConfirmation ? 'Create your 4-digit PIN' : 'Confirm your PIN',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  color: !_isPinConfirmation
                      ? (index < _pin.length ? Colors.deepPurple : Colors.grey.shade300)
                      : (index < _confirmPin.length ? Colors.deepPurple : Colors.grey.shade300),
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
          _buildNumPad(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNumPad() {
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
            Container(width: 80, height: 80), // Empty container for spacing
            _buildDigitButton('0'),
            SizedBox(
              width: 80,
              height: 80,
              child: IconButton(
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