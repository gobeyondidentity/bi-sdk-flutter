import 'dart:async';

import 'package:flutter/services.dart';

class Embeddedsdk {
  static const MethodChannel _channel =
      MethodChannel('embeddedsdk_method_channel');
  static const EventChannel _eventChannel =
      EventChannel('embeddedsdk_export_event_channel');
  static Function(Map<String, String?>)? _exportCallback;
  static StreamSubscription<dynamic>? _exportSubscription;

  /// Initialize and configure the Beyond Identity Embedded SDK.
  ///
  /// [allowedDomains] Optional array of domains that we whitelist against for network operations.
  /// This will default to Beyond Identity's allowed domains.
  /// [biometricPrompt] is the prompt the user will see when asked for biometrics while
  /// extending a credential to another device.
  /// [enableLogging] enables logging if set to `true`.
  static Future<void> initialize(String biometricPrompt, bool enableLogging,
      {List<String>? allowedDomains = const <String>[]}) async {
    await _channel.invokeMethod("initialize", {
      'allowedDomains': allowedDomains,
      'biometricPrompt': biometricPrompt,
      'enableLogging': enableLogging,
    });
  }

  /// Bind a credential to this device.
  ///
  /// [url] URL used to bind a credential to this device
  /// Returns a [BindCredentialResponse] or throws an [Exception]
  static Future<BindCredentialResponse> bindCredential(String url) async {
    final Map<String, dynamic>? bindCredentialResponse =
        await _channel.invokeMapMethod('bindCredential', {'url': url});

    try {
      return BindCredentialResponse(
        credential: Credential.mapToCredential(bindCredentialResponse?["credential"]),
        postBindingRedirectUri: bindCredentialResponse?["postBindingRedirectUri"],
      );
    } on Exception {
      rethrow;
    }
  }

  /// Authenticate a user.
  ///
  /// [url] URL used to authenticate
  /// [credentialId] The ID of the credential with which to authenticate.
  /// Returns a [AuthenticateResponse] or throws an [Exception]
  static Future<AuthenticateResponse> authenticate(String url, String credentialId) async {
    final Map<String, dynamic>? authenticateResponse =
        await _channel.invokeMapMethod('authenticate', {
      'url': url,
      'credentialId': credentialId,
    });

    try {
      return AuthenticateResponse(
        redirectUrl: authenticateResponse?["redirectUrl"],
        message: authenticateResponse?["message"],
      );
    } on Exception {
      rethrow;
    }
  }

  /// Get all current credentials for this device.
  ///
  /// Returns a [List] of [Credential]s
  static Future<List<Credential>> getCredentials() async {
    List<dynamic>? credentialListMap =
        await _channel.invokeListMethod("getCredentials");
    List<Credential> credentialList = List.empty(growable: true);

    if (credentialListMap != null) {
      try {
        credentialList = credentialListMap
            .map((cred) => Credential.mapToCredential(cred))
            .toList();
      } on Exception {
        rethrow;
      }
    } else {
      throw Exception("Error getting credentials from platform");
    }

    return credentialList;
  }

  /// Delete a [Credential] by ID on current device.
  ///
  /// Warning: deleting a [Credential] is destructive and will remove everything
  /// from the device. If no other device contains the credential then the user
  /// will need to complete a recovery in order to log in again on this device.
  ///
  /// [id] is the credential id, uniquely identifying a [Credential].
  static Future<void> deleteCredential(String id) async {
    await _channel.invokeMethod('deleteCredential', {
      'credentialId': id,
    });
  }

  /// Returns whether a Url is a valid Bind Credential Url or not.
  ///
  /// [url] A Url String
  static Future<bool> isBindCredentialUrl(String url) async {
    try {
      return await _channel.invokeMethod('isBindCredentialUrl', {'url': url});
    } on Exception {
      rethrow;
    }
  }

  /// Returns whether a Url is a valid Authenticate Url or not.
  ///
  /// [url] A Url String
  static Future<bool> isAuthenticateUrl(String url) async {
    try {
      return await _channel.invokeMethod('isAuthenticateUrl', {'url': url});
    } on Exception {
      rethrow;
    }
  }
}

/// A response returned after successfully binding a credential to a device.
class BindCredentialResponse {
  /// The [Credential] bound to the device.
  Credential credential;

  /// A URI that can be redirected to once a credential is bound. This could be a URI that automatically logs the user in with the newly bound credential, or a success page indicating that a credential has been bound.
  String postBindingRedirectUri;

  BindCredentialResponse({
    required this.credential,
    required this.postBindingRedirectUri,
  });

  String toJson() {
    return "{"
        "\"credential\":${credential.toJson()},"
        "\"postBindingRedirectUri\":\"$postBindingRedirectUri\"}";
  }

  @override
  String toString() {
    return "{\"BindCredentialResponse\":${toJson()}}";
  }
}

/// Represent User's credential, wrapper for X.509 Certificate
class Credential {
  /// The Globally unique ID of this Credential.
  String id;

  /// The time when this credential was created locally. This could be different from "created" which is the time when this credential was created on the server.
  String localCreated;

  /// The last time when this credential was updated locally. This could be different from "updated" which is the last time when this credential was updated on the server.
  String localUpdated;

  /// The base url for all binding & auth requests
  String apiBaseURL;

  /// The Identity's Tenant.
  String tenantId;

  /// The Identity's Realm.
  String realmId;

  /// The Identity that owns this Credential.
  String identityId;

  /// Associated key handle.
  String keyHandle;

  /// The current state of this credential
  CredentialState state;

  /// The time this credential was created.
  String created;

  /// The last time this credential was updated.
  String updated;

  /// Tenant information associated with this credential.
  Tenant tenant;

  /// Realm information associated with this credential.
  Realm realm;

  /// Identity information associated with this credential.
  Identity identity;

  /// Theme information associated with this credential
  Theme theme;

  Credential({
    required this.id,
    required this.localCreated,
    required this.localUpdated,
    required this.apiBaseURL,
    required this.tenantId,
    required this.realmId,
    required this.identityId,
    required this.keyHandle,
    required this.state,
    required this.created,
    required this.updated,
    required this.tenant,
    required this.realm,
    required this.identity,
    required this.theme,
  });

  static Credential mapToCredential(dynamic cred) {
    return Credential(
      id: cred["id"],
      localCreated: cred["localCreated"],
      localUpdated: cred["localUpdated"],
      apiBaseURL: cred["apiBaseUrl"],
      tenantId: cred["tenantId"],
      realmId: cred["realmId"],
      identityId: cred["identityId"],
      keyHandle: cred["keyHandle"],
      state: CredentialStateHelper.fromString(cred["state"]),
      created: cred["created"],
      updated: cred["updated"],
      tenant: Tenant.mapToTenant(cred["tenant"]),
      realm: Realm.mapToRealm(cred["realm"]),
      identity: Identity.mapToIdentity(cred["identity"]),
      theme: Theme.mapToTheme(cred["theme"]),
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"localCreated\":\"$localCreated\","
        "\"localUpdated\":\"$localUpdated\","
        "\"apiBaseURL\":\"$apiBaseURL\","
        "\"tenantId\":\"$tenantId\","
        "\"realmId\":\"$realmId\","
        "\"identityId\":\"$identityId\","
        "\"keyHandle\":\"$keyHandle\","
        "\"state\":\"$state\","
        "\"created\":\"$created\","
        "\"updated\":\"$updated\","
        "\"tenant\":${tenant.toJson()},"
        "\"realm\":${realm.toJson()},"
        "\"identity\":${identity.toJson()},"
        "\"theme\":${theme.toJson()}}";
  }

  @override
  String toString() {
    return "{\"Credential\":${toJson()}}";
  }
}

/// State of given [Credential]
enum CredentialState {
  /// [Credential] is active
  ACTIVE,

  /// [Credential] is revoked
  REVOKED,
}

class CredentialStateHelper {
  static CredentialState fromString(String state) {
    switch (state.toLowerCase()) {
      case "active":
        return CredentialState.ACTIVE;
      case "revoked":
        return CredentialState.REVOKED;
      default:
        throw Exception("Cannot initialize CredentialState from invalid String value $state");
    }
  }
}

/// Tenant information associated with a [Credential].
class Tenant {
  /// The display name of the tenant.
  String displayName;

  Tenant({
    required this.displayName,
  });

  static Tenant mapToTenant(dynamic cred) {
    return Tenant(
      displayName: cred["displayName"],
    );
  }

  String toJson() {
    return "{"
        "\"displayName\":\"$displayName\"}";
  }

  @override
  String toString() {
    return "{\"Tenant\":${toJson()}}";
  }
}

/// Realm information associated with a [Credential].
class Realm {
  /// The display name of the realm.
  String displayName;

  Realm({
    required this.displayName,
  });

  static Realm mapToRealm(dynamic cred) {
    return Realm(
      displayName: cred["displayName"],
    );
  }

  String toJson() {
    return "{"
        "\"displayName\":\"$displayName\"}";
  }

  @override
  String toString() {
    return "{\"Realm\":${toJson()}}";
  }
}

/// Identity information associated with a [Credential].
class Identity {
  /// The display name of the identity.
  String displayName;

  /// The username of the identity.
  String username;

  /// The primary email address of the identity.
  String? primaryEmailAddress;

  Identity({
    required this.displayName,
    required this.username,
    required this.primaryEmailAddress,
  });

  static Identity mapToIdentity(dynamic cred) {
    return Identity(
      displayName: cred["displayName"],
      username: cred["username"],
      primaryEmailAddress: cred["primaryEmailAddress"],
    );
  }

  String toJson() {
    return "{"
        "\"displayName\":\"$displayName\","
        "\"username\":\"$username\","
        "\"primaryEmailAddress\":\"$primaryEmailAddress\"}";
  }

  @override
  String toString() {
    return "{\"Identity\":${toJson()}}";
  }
}

/// Theme associated with a [Credential].
class Theme {
  /// URL to for resolving the logo image for light mode.
  String logoUrlLight;

  /// URL to for resolving the logo image for dark mode.
  String logoUrlDark;

  /// URL for customer support portal.
  String supportUrl;

  Theme({
    required this.logoUrlLight,
    required this.logoUrlDark,
    required this.supportUrl,
  });

  static Theme mapToTheme(dynamic cred) {
    return Theme(
      logoUrlLight: cred["logoLightUrl"],
      logoUrlDark: cred["logoDarkUrl"],
      supportUrl: cred["supportUrl"],
    );
  }

  String toJson() {
    return "{"
        "\"logoUrlLight\":\"$logoUrlLight\","
        "\"logoUrlDark\":\"$logoUrlDark\","
        "\"supportUrl\":\"$supportUrl\"}";
  }

  @override
  String toString() {
    return "{\"Theme\":${toJson()}}";
  }
}

/// A response returned after successfully authenticating.
class AuthenticateResponse {
  /// The redirect URL that originates from the /authorize call's `redirect_uri` parameter. The OAuth2 authorization `code` and the `state` parameter of the /authorize call are attached with the "code" and "state" parameters to this URL.
  String redirectUrl;

  /// An optional displayable message defined by policy returned by the cloud on success
  String message;

  AuthenticateResponse({
    required this.redirectUrl,
    required this.message,
  });

  String toJson() {
    return "{"
        "\"redirectUrl\":\"$redirectUrl\","
        "\"message\":\"$message\"}";
  }

  @override
  String toString() {
    return "{\"AuthenticateResponse\":${toJson()}}";
  }
}
