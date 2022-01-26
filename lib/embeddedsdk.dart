import 'dart:async';

import 'package:flutter/services.dart';

class Embeddedsdk {
  static const MethodChannel _channel = MethodChannel('embeddedsdk_method_channel');
  static const EventChannel _eventChannel = EventChannel('embeddedsdk_export_event_channel');
  static Function(Map<String, String?>)? _exportCallback;
  static StreamSubscription<dynamic>? _exportSubscription;

  static Future<void> initialize(String clientId, String biometricPrompt, String redirectUri, bool enableLogging) async {
    await _channel.invokeMethod("initialize", {
      'clientId': clientId,
      'biometricPrompt': biometricPrompt,
      'redirectUri': redirectUri,
      'enableLogging': enableLogging
    });
  }

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

  static void extendCredentials(
      List<String> credentialHandles,
      Function(Map<String, String?>) exportCallback) {
    _exportCallback = exportCallback;

    _exportSubscription = _eventChannel.receiveBroadcastStream(credentialHandles).listen((event) {
      if(_exportCallback != null) {
        _exportCallback!(event.cast<String, String?>());
      }
    });
  }

  static Future<void> cancelExtendCredentials() async {
    _exportSubscription!.cancel();
    await _channel.invokeMethod('cancelExtendCredentials');
  }

  static Future<String> deleteCredential(String handle) async {
    final String handleResult = await _channel.invokeMethod('deleteCredential', {
      'handle': handle,
    });
    return handleResult;
  }

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

  static Future<String> authorize(String scope, String? pkceS256CodeChallenge) async {
    final String authorizationCode = await _channel.invokeMethod('authorize', {
      'scope': scope,
      'pkceS256CodeChallenge': pkceS256CodeChallenge,
    });
    return authorizationCode;
  }

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

  static Future<PKCE> createPkce() async {
    final Map<String, dynamic>? pkceMap = await _channel.invokeMapMethod("createPkce");
    return PKCE(
      codeVerifier: pkceMap?["codeVerifier"],
      codeChallenge: pkceMap?["codeChallenge"],
      codeChallengeMethod: pkceMap?["codeChallengeMethod"],
    );
  }

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

class PKCE {
  String codeVerifier;
  String codeChallenge;
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

class Credential {
  String created;
  String handle;
  String keyHandle;
  String name;
  String logoURL;
  String? loginURI;
  String? enrollURI;
  List chain;
  String rootFingerprint;

  Credential(
      {required this.created,
      required this.handle,
      required this.keyHandle,
      required this.name,
      required this.logoURL,
      required this.loginURI,
      required this.enrollURI,
      required this.chain,
      required this.rootFingerprint});

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

class TokenResponse {
  String accessToken;
  String idToken;
  String tokenType;
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
