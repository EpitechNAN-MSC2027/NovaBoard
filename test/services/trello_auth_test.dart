import 'package:flutter_test/flutter_test.dart';
import 'package:nova_board/services/trello_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart';
import 'trello_auth_test.mocks.dart';

@GenerateMocks([
  FlutterSecureStorage,
  LocalAuthentication,
  Client,
])
void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockAuth;
  late MockClient mockHttpClient;
  late TrelloAuthService authService;

  setUp(() async {
    await dotenv.load(fileName: ".env");
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockLocalAuthentication();
    mockHttpClient = MockClient();

    authService = TrelloAuthService(
      storage: mockStorage,
      auth: mockAuth,

    );
  });

  test('Nonce generation returns 32-char hex string', () {
    final nonce = authService.generateNonce();
    expect(nonce.length, 64);
  });

  test('OAuth signature generation returns non-empty string', () {
    final signature = authService.generateSignature(
      'POST',
      'https://trello.com/1/OAuthGetRequestToken',
      {
        'oauth_consumer_key': 'key',
        'oauth_nonce': 'nonce',
        'oauth_timestamp': '1234567890',
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_version': '1.0',
        'oauth_callback': 'novaboard://callback',
      },
      'secret',
      '',
    );
    expect(signature, isNotEmpty);
  });

  test('Authorization header is correctly formatted', () {
    final authHeader = authService.buildAuthHeader(
      {'oauth_consumer_key': 'key', 'oauth_nonce': 'nonce'},
      'signature123',
    );
    expect(authHeader, contains('OAuth'));
    expect(authHeader, contains('oauth_signature="signature123"'));
  });

  test('Biometrics availability returns false when not supported', () async {
    when(mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

    final result = await authService.isBiometricsAvailable();
    expect(result, isFalse);
  });

  test('isBiometricsAvailable retourne true quand supporté', () async {
    when(mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(mockAuth.isDeviceSupported()).thenAnswer((_) async => true);

    final result = await authService.isBiometricsAvailable();
    expect(result, true);
  });

  test('Biometric authentication fails gracefully', () async {
    when(mockAuth.authenticate(
      localizedReason: anyNamed('localizedReason'),
      options: anyNamed('options'),
    )).thenThrow(Exception('Biometric error'));

    final result = await authService.authenticateWithBiometrics();
    expect(result, isFalse);
  });

  test('authenticateWithBiometrics retourne true en cas de succès', () async {
    when(mockAuth.authenticate(
      localizedReason: anyNamed('localizedReason'),
      options: anyNamed('options'),
    )).thenAnswer((_) async => true);

    final result = await authService.authenticateWithBiometrics();
    expect(result, true);
  });

  test('isPinSetup returns true when pin_setup_complete is true', () async {
    when(mockStorage.read(key: 'pin_setup_complete'))
        .thenAnswer((_) async => 'true');

    final result = await authService.isPinSetup();
    expect(result, isTrue);
  });

  test('getStoredAccessToken returns token', () async {
    when(mockStorage.read(key: 'trello_access_token'))
        .thenAnswer((_) async => 'token123');

    final token = await authService.getStoredAccessToken();
    expect(token, 'token123');
  });

  test('Logout clears tokens from storage', () async {
    await authService.logout();
    verify(mockStorage.delete(key: 'trello_access_token')).called(1);
    verify(mockStorage.delete(key: 'oauth_token_secret')).called(1);
  });

}
