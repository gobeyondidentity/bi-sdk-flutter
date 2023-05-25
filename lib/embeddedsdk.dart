import 'dart:async';

import 'package:flutter/services.dart';

class Embeddedsdk {
  static const MethodChannel _channel = MethodChannel('embeddedsdk_method_channel');
  static const EventChannel _eventChannel = EventChannel('embeddedsdk_export_event_channel');
  static Function(Map<String, String?>)? _exportCallback;
  static StreamSubscription<dynamic>? _exportSubscription;

  /// Initialize and configure the Beyond Identity Embedded SDK.
  ///
  /// [clientId] is the public or confidential client ID generated during the OIDC configuration.
  /// [domain] is the region where your Beyond Identity account was created (us or eu).
  /// [biometricPrompt] is the prompt the user will see when asked for biometrics while
  /// extending a credential to another device.
  /// [redirectUri] is the URI where the user will be redirected after the authorization
  /// has completed. The redirect URI must be one of the URIs passed in the OIDC configuration.
  /// [enableLogging] enables logging if set to `true`.
  static Future<void> initialize(
    String clientId,
    Domain domain,
    String biometricPrompt,
    String redirectUri,
    bool enableLogging,
  ) async {
    await _channel.invokeMethod("initialize", {
      'clientId': clientId,
      'domain': domain.toString(),
      'biometricPrompt': biometricPrompt,
      'redirectUri': redirectUri,
      'enableLogging': enableLogging
    });
  }

  /// Use a registration link to create and register a credential.
  ///
  /// [registerUri] is the URI used to create a credential.
  /// Returns the `Credential` that was created and registered with Beyond Identity.
  static Future<Credential> registerCredentialsWithUrl(String registerUri) async {
    final Map<String, dynamic>? credentialMap = await _channel.invokeMapMethod('registerCredentialsWithUrl', {
      'registerUri': registerUri,
    });

    if (credentialMap != null) {
      try {
        return Credential.mapToCredential(credentialMap);
      } on Exception {
        rethrow;
      }
    } else {
      throw Exception("Error getting values from platform for registerCredentialsWithUrl");
    }
  }

  /// Extend a list of credentials from one device to another.
  ///
  /// The user must be in an authenticated state to extend any credentials.
  /// During this flow the user is prompted for a biometric challenge. If
  /// biometrics are not set, it falls back to PIN.
  ///
  /// After the challenge is completed, a rendezvous token is provided with
  /// 90 seconds time-to-live, after which a new token is generated.
  ///
  /// NOTE: to cancel the credentials flow, [cancelExtendCredentials]
  /// must be invoked.
  ///
  /// [credentialHandles] is the list of credential handles to extend.
  /// [exportCallback] is a callback that receives status updates during the
  /// execution of the flow. Its argument is a map with the following contents:
  ///
  /// * "status": one of constant values in the [ExtendCredentialsStatus] class.
  /// * "token": only present if status is "update". Contains the new rendezvous
  ///   token value.
  /// * "errorMessage": only present if status is "error". Contains the error
  ///   message.
  static void extendCredentials(List<String> credentialHandles, Function(Map<String, String?>) exportCallback) {
    _exportCallback = exportCallback;

    _exportSubscription = _eventChannel.receiveBroadcastStream(credentialHandles).listen((event) {
      if (_exportCallback != null) {
        _exportCallback!(event.cast<String, String?>());
      }
    });
  }

  /// Cancels ongoing extend requests.
  static Future<void> cancelExtendCredentials() async {
    _exportSubscription!.cancel();
    await _channel.invokeMethod('cancelExtendCredentials');
  }

  /// Delete a [Credential] by handle.
  ///
  /// Warning: deleting a [Credential] is destructive and will remove everything
  /// from the device. If no other device contains the credential then the user
  /// will need to complete a recovery in order to log in again on this device.
  ///
  /// [handle] is the credential handle uniquely identifying the [Credential] to
  /// delete.
  static Future<String> deleteCredential(String handle) async {
    final String handleResult = await _channel.invokeMethod('deleteCredential', {
      'handle': handle,
    });
    return handleResult;
  }

  /// Register a [Credential] with a rendezvous token.
  ///
  /// Use this function to register a [Credential] from one device to another.
  /// NOTE: only one credential per device is currently supported.
  ///
  /// [token] is a rendezvous token received during the export flow initiated
  /// by calling [extendCredentials].
  ///
  /// Returns the list of credentials registered.
  static Future<List<Credential>> registerCredentialsWithToken(String token) async {
    List<dynamic>? credentialListMap = await _channel.invokeListMethod('registerCredentialsWithToken', {
      'token': token,
    });
    List<Credential> credentialList = List.empty(growable: true);

    if (credentialListMap != null) {
      try {
        credentialList = credentialListMap.map((cred) => Credential.mapToCredential(cred)).toList();
      } on Exception {
        rethrow;
      }
    } else {
      throw Exception("Error getting credentials from platform");
    }

    return credentialList;
  }

  /// Initiate authentication via the OIDC authorization code flow for confidential clients.
  ///
  /// An app implementing the Embedded SDK initiates an authentication request
  /// with Beyond Identity. Using the confidential client API assumes that a secure
  /// backend exists that can safely store the client secret and can exchange
  /// the authorization code for an access and ID token.
  ///
  /// [scope] is the OIDC scope used during authentication. Only "openid" is
  /// currently supported.
  /// [pkceS256CodeChallenge] is an optional, but recommended PKCE challenge
  /// used to prevent authorization code injection that can be obtained by
  /// invoking [createPkce].
  ///
  /// Returns the authorization code that can be used to redeem tokens from
  /// the Beyond Identity token endpoint.
  static Future<String> authorize(String scope, String? pkceS256CodeChallenge) async {
    final String authorizationCode = await _channel.invokeMethod('authorize', {
      'scope': scope,
      'pkceS256CodeChallenge': pkceS256CodeChallenge,
    });
    return authorizationCode;
  }

  /// Initiate authentication via the OIDC authorization code flow for public clients.
  ///
  /// An app implementing the Embedded SDK initiates an authentication request
  /// with Beyond Identity. Using the public client API assumes that there is
  /// no secure backend storing the client secret for the app.
  ///
  /// Returns the access and ID tokens, plus expiration times in a [TokenResponse]
  /// object.
  static Future<TokenResponse> authenticate() async {
    final Map<String, dynamic>? tokenMap = await _channel.invokeMapMethod('authenticate');

    try {
      return TokenResponse(
        accessToken: tokenMap?["accessToken"],
        idToken: tokenMap?["idToken"],
        tokenType: tokenMap?["tokenType"],
        expiresIn: tokenMap?["expiresIn"],
      );
    } on Exception {
      rethrow;
    }
  }

  /// Creates PKCE authentication request parameters.
  ///
  /// For more information on PKCE see https://datatracker.ietf.org/doc/html/rfc7636.
  ///
  /// Returns a set of new parameters in a [PKCE] object.
  static Future<PKCE> createPkce() async {
    final Map<String, dynamic>? pkceMap = await _channel.invokeMapMethod("createPkce");
    return PKCE(
      codeVerifier: pkceMap?["codeVerifier"],
      codeChallenge: pkceMap?["codeChallenge"],
      codeChallengeMethod: pkceMap?["codeChallengeMethod"],
    );
  }

  /// Get all current credentials for this device.
  ///
  /// NOTE: only one credential per device is supported currently.
  static Future<List<Credential>> getCredentials() async {
    List<dynamic>? credentialListMap = await _channel.invokeListMethod("getCredentials");
    List<Credential> credentialList = List.empty(growable: true);

    if (credentialListMap != null) {
      try {
        credentialList = credentialListMap.map((cred) => Credential.mapToCredential(cred)).toList();
      } on Exception {
        rethrow;
      }
    } else {
      throw Exception("Error getting credentials from platform");
    }

    return credentialList;
  }
}

/// Represent PKCE authorization request parameters.
class PKCE {
  /// A cryptographically random string.
  String codeVerifier;
  /// A challenge derived from the code verifier.
  String codeChallenge;
  /// A method that was used to derive code challenge.
  String codeChallengeMethod;

  PKCE({required this.codeVerifier, required this.codeChallenge, required this.codeChallengeMethod});

  @override
  String toString() {
    return "PKCE = ["
        "codeVerifier = $codeVerifier, "
        "codeChallenge = $codeChallenge, "
        "codeChallengeMethod = $codeChallengeMethod]";
  }
}

/// Represent User's credential, wrapper for X.509 Certificate
class Credential {
  /// The date the [Credential] was created.
  String created;
  /// The handle for the `Credential`.
  String handle;
  /// The keystore key handle.
  String keyHandle;
  /// The display name of the `Credential`.
  String name;
  /// The uri of your company or app's logo.
  String logoURL;
  /// The uri of your app's sign in screen. This is where the user would authenticate into your app.
  String? loginURI;
  /// The uri of your app's sign up screen. This is where the user would register with your service.
  String? enrollURI;
  /// The certificate chain of the [Credential].
  List chain;
  /// The SHA256 hash of the root certificate as a base64 encoded string.
  String rootFingerprint;
  /// Current state of the [Credential]
  CredentialState state;

  Credential(
      {required this.created,
      required this.handle,
      required this.keyHandle,
      required this.name,
      required this.logoURL,
      required this.loginURI,
      required this.enrollURI,
      required this.chain,
      required this.rootFingerprint,
      required this.state});

  static Credential mapToCredential(dynamic cred) {
    return Credential(
      created: cred["created"],
      handle: cred["handle"],
      keyHandle: cred["keyHandle"],
      name: cred["name"],
      logoURL: cred["logoURL"],
      loginURI: cred["loginURI"],
      enrollURI: cred["enrollURI"],
      chain: cred["chain"],
      rootFingerprint: cred["rootFingerprint"],
      state: CredentialStateHelper.fromString(cred["state"])
    );
  }

  @override
  String toString() {
    return "Credential = "
        "[created = $created, "
        "handle = $handle, "
        "keyHandle = $keyHandle, "
        "name = $name, "
        "logoURL = $logoURL, "
        "loginURI = $loginURI, "
        "enrollURI = $enrollURI, "
        "chain = $chain, "
        "rootFingerprint = $rootFingerprint]";
  }
}

class ExtendCredentialsStatus {
  static const String status = "status";
  static const String update = "update";
  static const String finish = "finish";
  static const String error = "error";
}

/// OAuth token grant
class TokenResponse {
  /// OAuth token grant
  String accessToken;
  /// OIDC JWT token grant
  String idToken;
  /// type such as "Bearer"
  String tokenType;
  /// expiration of the [accessToken]
  int expiresIn;

  TokenResponse({
    required this.accessToken,
    required this.idToken,
    required this.tokenType,
    required this.expiresIn,
  });

  @override
  String toString() {
    return "TokenResponse = "
        "[accessToken = $accessToken, "
        "idToken = $idToken, "
        "tokenType = $tokenType, "
        "expiresIn = $expiresIn]";
  }
}

/// State of given [Credential]
enum CredentialState {
  /// Credential is active
  active,
  /// Device has been deleted
  deviceDeleted,
  /// One or more fields failed their integrity checks
  invalid,
  /// User has been deleted
  userDeleted,
  /// User is suspended
  userSuspended,
  /// Unable to determine the state of the credential
  unknown
}

class CredentialStateHelper {
  static CredentialState fromString(String? state) {
    if (state == null) {
      return CredentialState.unknown;
    }

    switch (state) {
      case "active":
        return CredentialState.active;
      case "deviceDeleted":
        return CredentialState.deviceDeleted;
      case "userDeleted":
        return CredentialState.userDeleted;
      case "userSuspended":
        return CredentialState.userSuspended;
      case "invalid":
        return CredentialState.invalid;
      default:
        return CredentialState.unknown;
    }
  }
}

enum Domain {
  us,
  eu,
}
