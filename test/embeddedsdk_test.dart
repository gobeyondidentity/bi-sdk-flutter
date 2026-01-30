import 'package:bi_sdk_flutter/embeddedsdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('embeddedsdk_method_channel');

  // ignore: constant_identifier_names
  const String TEST_AUTHENTICATE_URL =
      "https://auth-us.beyondidentity.com/bi-authenticate?request=0123456789ABCDEF";
  // ignore: constant_identifier_names
  const String TEST_BIND_PASSKEY_URL =
      "https://auth-us.beyondidentity.com/v1/tenants/0123456789ABCDEF/realms/0123456789ABCDEF/identities/0123456789ABCDEF/credential-binding-jobs/0123456789ABCDEF:invokeAuthenticator?token=0123456789ABCDEF";

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getPasskeys':
          return [createPasskey()];
        case 'isBindPasskeyUrl':
          return methodCall.arguments['url'] == TEST_BIND_PASSKEY_URL;
        case 'isAuthenticateUrl':
          return methodCall.arguments['url'] == TEST_AUTHENTICATE_URL;
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPasskeys', () async {
    List<Passkey> passkeys = await EmbeddedSdk.getPasskeys();
    expect(passkeys[0].id, "01234567-89AB-CDEF-0123-456789ABCDEF");
    expect(passkeys[0].passkeyId, "0123456789ABCDEF");
    expect(passkeys[0].localCreated, "2022-06-15T12:00:00");
    expect(passkeys[0].localUpdated, "2022-06-15T12:00:00");
    expect(passkeys[0].apiBaseUrl, "https://auth-us.beyondidentity.com");
    expect(passkeys[0].keyHandle, "km:0123456789ABCDEF");
    expect(passkeys[0].state, PasskeyState.ACTIVE);
    expect(passkeys[0].created, "2022-06-15T12:00:00");
    expect(passkeys[0].updated, "2022-06-15T12:00:00");
    expect(passkeys[0].tenant.id, "0123456789ABCDEF");
    expect(passkeys[0].tenant.displayName, "Beyond Identity");
    expect(passkeys[0].realm.id, "0123456789ABCDEF");
    expect(passkeys[0].realm.displayName, "Beyond Identity");
    expect(passkeys[0].identity.id, "0123456789ABCDEF");
    expect(passkeys[0].identity.displayName, "Beyond Identity");
    expect(passkeys[0].identity.username, "Beyond Identity");
    expect(passkeys[0].identity.primaryEmailAddress, "foo.bar@beyondidentity.com");
    expect(passkeys[0].theme.logoLightUrl, "https://static.byndid.com/logos/beyondidentity.png");
    expect(passkeys[0].theme.logoDarkUrl, "https://static.byndid.com/logos/beyondidentity.png");
    expect(passkeys[0].theme.supportUrl, "https://www.beyondidentity.com/support");
  });

  test('isBindPasskeyUrlFailure', () async {
    bool isBindPasskeyUrl =
        await EmbeddedSdk.isBindPasskeyUrl(TEST_AUTHENTICATE_URL);
    expect(isBindPasskeyUrl, false);
  });

  test('isBindPasskeyUrlSuccess', () async {
    bool isBindPasskeyUrl =
        await EmbeddedSdk.isBindPasskeyUrl(TEST_BIND_PASSKEY_URL);
    expect(isBindPasskeyUrl, true);
  });

  test('isAuthenticateUrlFailure', () async {
    bool isAuthenticateUrl =
        await EmbeddedSdk.isAuthenticateUrl(TEST_BIND_PASSKEY_URL);
    expect(isAuthenticateUrl, false);
  });

  test('isAuthenticateUrlSuccess', () async {
    bool isAuthenticateUrl =
        await EmbeddedSdk.isAuthenticateUrl(TEST_AUTHENTICATE_URL);
    expect(isAuthenticateUrl, true);
  });
}

Map<String, dynamic> createPasskey() {
  return {
    "id": "01234567-89AB-CDEF-0123-456789ABCDEF",
    "passkeyId": "0123456789ABCDEF",
    "localCreated": "2022-06-15T12:00:00",
    "localUpdated": "2022-06-15T12:00:00",
    "apiBaseUrl": "https://auth-us.beyondidentity.com",
    "keyHandle": "km:0123456789ABCDEF",
    "state": "Active",
    "created": "2022-06-15T12:00:00",
    "updated": "2022-06-15T12:00:00",
    "tenant": {
      "id": "0123456789ABCDEF",
      "displayName": "Beyond Identity",
    },
    "realm": {
      "id": "0123456789ABCDEF",
      "displayName": "Beyond Identity",
    },
    "identity": {
      "id": "0123456789ABCDEF",
      "displayName": "Beyond Identity",
      "username": "Beyond Identity",
      "primaryEmailAddress": "foo.bar@beyondidentity.com",
    },
    "theme": {
      "logoLightUrl": "https://static.byndid.com/logos/beyondidentity.png",
      "logoDarkUrl": "https://static.byndid.com/logos/beyondidentity.png",
      "supportUrl": "https://www.beyondidentity.com/support",
    },
  };
}
