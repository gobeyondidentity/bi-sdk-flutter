import 'package:embeddedsdk/embeddedsdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('embeddedsdk_method_channel');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'authorize':
          return 'authz_code_123';
        case 'createPkce':
          return {
            "codeVerifier": "123",
            "codeChallenge": "321",
            "codeChallengeMethod": "S256",
          };
        case 'getCredentials':
          return [
            createCredentail()
          ];
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getAuthorizationCode', () async {
    expect(await Embeddedsdk.authorize("scope", null), 'authz_code_123');
  });

  test('getPkce', () async {
    PKCE pkce = await Embeddedsdk.createPkce();
    expect(pkce.codeChallenge, "321");
  });

  test('getCredentials', () async {
    List<Credential> credentials = await Embeddedsdk.getCredentials();
    expect(credentials[0].handle, "handle_123");
    expect(credentials[0].chain[0], "chain_1");
    expect(credentials[0].loginURI, null);
    expect(credentials[0].enrollURI, null);
  });
}

Map<String, dynamic> createCredentail() {
  return {
    "created": "123",
    "handle": "handle_123",
    "keyHandle": "key_handle_123",
    "name": "name_123",
    "logoURL": "name_123",
    "loginURI": null,
    "enrollURI": null,
    "chain": ["chain_1"],
    "rootFingerprint": "name_123",
  };
}
