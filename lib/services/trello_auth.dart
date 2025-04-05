import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:crypto/crypto.dart';

class TrelloAuthService {
  final String apiKey = dotenv.env['TRELLO_API_KEY'] ?? '';
  final String apiSecret = dotenv.env['TRELLO_API_SECRET'] ?? '';
  final String callbackUrlScheme = 'novaboard';
  final FlutterSecureStorage storage;
  final LocalAuthentication auth;

  TrelloAuthService({
    FlutterSecureStorage? storage,
    LocalAuthentication? auth,
  })  : storage = storage ?? const FlutterSecureStorage(),
        auth = auth ?? LocalAuthentication();

  /// Authenticate with Trello OAuth
  Future<void> authenticateWithTrello() async {
    try {
      final oauthToken = await _getRequestToken();

      final authorizationUrl =
          'https://trello.com/1/OAuthAuthorizeToken?oauth_token=$oauthToken&name=NovaBoard&scope=read,write&expiration=never';

      final result = await FlutterWebAuth.authenticate(
        url: authorizationUrl,
        callbackUrlScheme: callbackUrlScheme,
        preferEphemeral: true,
      );

      final uri = Uri.parse(result);
      final oauthVerifier = uri.queryParameters['oauth_verifier'];

      if (oauthVerifier == null) {
        throw Exception('Missing oauth_verifier in callback');
      }

      final accessToken = await _getAccessToken(oauthToken, oauthVerifier);
      await storage.write(key: 'trello_access_token', value: accessToken);

      return;
    } catch (e) {
      print('Authentication Error: $e');
      rethrow;
    }
  }

  /// Get OAuth request token
  Future<String> _getRequestToken() async {
    final url = 'https://trello.com/1/OAuthGetRequestToken';
    final oauthNonce = generateNonce();
    final oauthTimestamp =
    (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final params = {
      'oauth_consumer_key': apiKey,
      'oauth_nonce': oauthNonce,
      'oauth_timestamp': oauthTimestamp,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_version': '1.0',
      'oauth_callback': '$callbackUrlScheme://callback',
    };


    final signature = generateSignature('POST', url, params, apiSecret, '');
    final authHeader = buildAuthHeader(params, signature);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': authHeader},
    );

    if (response.statusCode == 200) {
      final responseParams = Uri.splitQueryString(response.body);
      final oauthToken = responseParams['oauth_token']!;
      final oauthTokenSecret = responseParams['oauth_token_secret']!;

      // Store token secret for later use in _getAccessToken()
      await storage.write(key: 'oauth_token_secret', value: oauthTokenSecret);

      return oauthToken;
    } else {
      print("Error Response: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to obtain request token');
    }
  }

  /// Get OAuth access token
  Future<String> _getAccessToken(
      String oauthToken, String? oauthVerifier) async {
    final url = 'https://trello.com/1/OAuthGetAccessToken';
    final oauthNonce = generateNonce();
    final oauthTimestamp =
    (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Retrieve oauth_token_secret stored earlier
    String? oauthTokenSecret = await storage.read(key: 'oauth_token_secret');
    if (oauthTokenSecret == null) {
      throw Exception('Missing oauth_token_secret');
    }

    final params = {
      'oauth_consumer_key': apiKey,
      'oauth_token': oauthToken,
      'oauth_nonce': oauthNonce,
      'oauth_timestamp': oauthTimestamp,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_version': '1.0',
      'oauth_verifier': oauthVerifier!,
    };

    final signature = generateSignature('POST', url, params, apiSecret, oauthTokenSecret);
    final authHeader = buildAuthHeader(params, signature);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': authHeader},
    );

    if (response.statusCode == 200) {
      final responseParams = Uri.splitQueryString(response.body);

      return responseParams['oauth_token']!;
    } else {
      throw Exception('Failed to obtain access token');
    }
  }

  /// Check if biometrics are available on the device
  Future<bool> isBiometricsAvailable() async {
    try {
      // Check if the device supports biometrics
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      // Check if the device is capable of checking biometrics
      bool isBiometricSupported = await auth.isDeviceSupported();
      return canCheckBiometrics && isBiometricSupported;
    } on Exception catch (e) {
      print('Biometric Availability Check Error: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access your Trello account',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
    } on Exception catch (e) {
      print('Biometric Authentication Error: $e');
    }
    return authenticated;
  }

  /// Check if PIN has been set up
  Future<bool> isPinSetup() async {
    String? isPinSetup = await storage.read(key: 'pin_setup_complete');
    return isPinSetup == 'true';
  }

  /// Retrieve stored Trello access token
  Future<String?> getStoredAccessToken() async {
    return await storage.read(key: 'trello_access_token');
  }

  /// Helper: Generate OAuth nonce
  String generateNonce() {
    final random = Random();
    return List.generate(32, (_) => random.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Helper: Generate OAuth signature
  String generateSignature(String method, String url,
      Map<String, String> params, String consumerSecret, String tokenSecret) {
    final encodedParams = params.keys
        .map((key) =>
    '${Uri.encodeComponent(key)}=${Uri.encodeComponent(params[key]!)}')
        .toList()
      ..sort();
    final baseString =
        '$method&${Uri.encodeComponent(url)}&${Uri.encodeComponent(encodedParams.join('&'))}';


    final signingKey = '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';
    final hmacSha1 = Hmac(sha1, utf8.encode(signingKey));
    final signature = base64Encode(hmacSha1.convert(utf8.encode(baseString)).bytes);

    return signature;
  }

  /// Helper: Build OAuth Authorization Header
  String buildAuthHeader(Map<String, String> params, String signature) {
    final authParams = {...params, 'oauth_signature': signature};
    return 'OAuth ${authParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}="${Uri.encodeComponent(e.value)}"')
            .join(', ')}';
  }

  Future<void> logout() async {
    await storage.delete(key: 'trello_access_token');
    await storage.delete(key: 'oauth_token_secret');
  }
}
