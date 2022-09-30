import 'package:bi_sdk_flutter/embeddedsdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('embeddedsdk_method_channel');

  // ignore: constant_identifier_names
  const String TEST_AUTHENTICATE_URL =
      "https://auth-us.beyondidentity.com/bi-authenticate?request=0123456789ABCDEF";
  // ignore: constant_identifier_names
  const String TEST_BIND_CREDENTIAL_URL =
      "https://auth-us.beyondidentity.com/v1/tenants/0123456789ABCDEF/realms/0123456789ABCDEF/identities/0123456789ABCDEF/credential-binding-jobs/0123456789ABCDEF:invokeAuthenticator?token=0123456789ABCDEF";

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getCredentials':
          return [createCredential()];
        case 'isBindCredentialUrl':
          return methodCall.arguments['url'] == TEST_BIND_CREDENTIAL_URL;
        case 'isAuthenticateUrl':
          return methodCall.arguments['url'] == TEST_AUTHENTICATE_URL;
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getCredentials', () async {
    List<Credential> credentials = await Embeddedsdk.getCredentials();
    expect(credentials[0].id, "01234567-89AB-CDEF-0123-456789ABCDEF");
    expect(credentials[0].localCreated, "2022-06-15T12:00:00");
    expect(credentials[0].localUpdated, "2022-06-15T12:00:00");
    expect(credentials[0].apiBaseURL, "https://auth-us.beyondidentity.com");
    expect(credentials[0].tenantId, "0123456789ABCDEF");
    expect(credentials[0].realmId, "0123456789ABCDEF");
    expect(credentials[0].identityId, "0123456789ABCDEF");
    expect(credentials[0].keyHandle, "km:0123456789ABCDEF");
    expect(credentials[0].state, CredentialState.ACTIVE);
    expect(credentials[0].created, "2022-06-15T12:00:00");
    expect(credentials[0].updated, "2022-06-15T12:00:00");
    expect(credentials[0].tenant.displayName, "Beyond Identity");
    expect(credentials[0].realm.displayName, "Beyond Identity");
    expect(credentials[0].identity.displayName, "Beyond Identity");
    expect(credentials[0].identity.username, "Beyond Identity");
    expect(credentials[0].identity.primaryEmailAddress, "foo.bar@beyondidentity.com");
    expect(credentials[0].theme.logoUrlLight,
        "https://byndid-public-assets.s3-us-west-2.amazonaws.com/logos/beyondidentity.png");
    expect(credentials[0].theme.logoUrlDark,
        "https://byndid-public-assets.s3-us-west-2.amazonaws.com/logos/beyondidentity.png");
    expect(credentials[0].theme.supportUrl,
        "https://www.beyondidentity.com/support");
  });

  test('isBindCredentialUrlFailure', () async {
    bool isBindCredentialUrl =
        await Embeddedsdk.isBindCredentialUrl(TEST_AUTHENTICATE_URL);
    expect(isBindCredentialUrl, false);
  });

  test('isBindCredentialUrlSuccess', () async {
    bool isBindCredentialUrl =
        await Embeddedsdk.isBindCredentialUrl(TEST_BIND_CREDENTIAL_URL);
    expect(isBindCredentialUrl, true);
  });

  test('isAuthenticateUrlFailure', () async {
    bool isAuthenticateUrl =
        await Embeddedsdk.isAuthenticateUrl(TEST_BIND_CREDENTIAL_URL);
    expect(isAuthenticateUrl, false);
  });

  test('isAuthenticateUrlSuccess', () async {
    bool isAuthenticateUrl =
        await Embeddedsdk.isAuthenticateUrl(TEST_AUTHENTICATE_URL);
    expect(isAuthenticateUrl, true);
  });
}

Map<String, dynamic> createCredential() {
  return {
    "id": "01234567-89AB-CDEF-0123-456789ABCDEF",
    "localCreated": "2022-06-15T12:00:00",
    "localUpdated": "2022-06-15T12:00:00",
    "apiBaseUrl": "https://auth-us.beyondidentity.com",
    "tenantId": "0123456789ABCDEF",
    "realmId": "0123456789ABCDEF",
    "identityId": "0123456789ABCDEF",
    "keyHandle": "km:0123456789ABCDEF",
    "state": "Active",
    "created": "2022-06-15T12:00:00",
    "updated": "2022-06-15T12:00:00",
    "tenant": {
      "displayName": "Beyond Identity",
    },
    "realm": {
      "displayName": "Beyond Identity",
    },
    "identity": {
      "displayName": "Beyond Identity",
      "username": "Beyond Identity",
      "primaryEmailAddress": "foo.bar@beyondidentity.com",
    },
    "theme": {
      "logoLightUrl":
          "https://byndid-public-assets.s3-us-west-2.amazonaws.com/logos/beyondidentity.png",
      "logoDarkUrl":
          "https://byndid-public-assets.s3-us-west-2.amazonaws.com/logos/beyondidentity.png",
      "supportUrl": "https://www.beyondidentity.com/support",
    },
  };
}
