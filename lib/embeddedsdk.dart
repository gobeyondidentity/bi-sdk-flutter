import 'dart:async';

import 'package:bi_sdk_flutter/print.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EmbeddedSdk {
  static const MethodChannel _channel =
      MethodChannel('embeddedsdk_method_channel');

  /// Initialize and configure the Beyond Identity Embedded SDK.
  ///
  /// [allowedDomains] Optional array of domains that we whitelist against for network operations.
  /// This will default to Beyond Identity's allowed domains.
  /// [biometricAskPrompt] A prompt the user will see when asked for biometrics while extending a passkey to another device.
  /// [logger] Custom logger to get logs from the SDK.
  /// To enable logging, pass [EmbeddedSdk.enableLogger], otherwise, pass null.
  static Future<void> initialize(
    String biometricAskPrompt, {
    List<String>? allowedDomains = const <String>[],
    Future<Function>? logger,
  }) async {
    await _channel.invokeMethod("initialize", {
      'allowedDomains': allowedDomains,
      'biometricAskPrompt': biometricAskPrompt,
      'enableLogger': logger != null,
    });
  }

  /// Custom logger to get logs from the SDK.
  /// This must be called from within a [State].
  static Future<Function> enableLogger() async {
    return await enablePrinting();
  }

  /// Bind a passkey to this device.
  ///
  /// [url] URL used to bind a passkey to this device
  /// Returns a [BindPasskeyResponse] or throws an [Exception]
  static Future<BindPasskeyResponse> bindPasskey(String url) async {
    final Map<String, dynamic>? bindPasskeyResponse =
        await _channel.invokeMapMethod('bindPasskey', {'url': url});

    try {
      return BindPasskeyResponse(
        passkey: Passkey.mapToPasskey(bindPasskeyResponse?["passkey"]),
        postBindingRedirectUri: bindPasskeyResponse?["postBindingRedirectUri"],
      );
    } on Exception {
      rethrow;
    }
  }

  /// Authenticate a user.
  ///
  /// [url] URL used to authenticate
  /// [passkeyId] The ID of the passkey with which to authenticate.
  /// Returns a [AuthenticateResponse] or throws an [Exception]
  static Future<AuthenticateResponse> authenticate(
      String url, String passkeyId) async {
    final Map<String, dynamic>? authenticateResponse =
        await _channel.invokeMapMethod('authenticate', {
      'url': url,
      'passkeyId': passkeyId,
    });

    try {
      return AuthenticateResponse(
        redirectUrl: authenticateResponse?["redirectUrl"],
        message: authenticateResponse?["message"],
        passkeyBindingToken: authenticateResponse?["passkeyBindingToken"]
      );
    } on Exception {
      rethrow;
    }
  }

  /// Initiates authentication using an OTP, which will be sent to the provided email address.
  ///
  /// [url] The authentication URL of the current transaction.
  /// [email] The email address where the OTP will be sent.
  /// Returns a [OtpChallengeResponse] or throws an [Exception]
  static Future<OtpChallengeResponse> authenticateOtp(
      String url, String email) async {
    final Map<String, dynamic>? otpChallengeResponse =
        await _channel.invokeMapMethod('authenticateOtp', {
      'url': url,
      'email': email,
    });

    try {
      return OtpChallengeResponse(
        url: otpChallengeResponse?["url"],
      );
    } on Exception {
      rethrow;
    }
  }

  /// Get the Authentication Context for the current transaction.
  ///
  /// The Authentication Context contains the Authenticator Config, Authentication Method Configuration, request origin, and the authenticating application.
  /// This is used to retrieve authentication parameters for an ongoing transaction.
  ///
  /// [url] The authentication URL of the current transaction.
  /// Returns a [AuthenticationContext] or throws an [Exception]
  static Future<AuthenticationContext> getAuthenticationContext(
      String url) async {
    final Map<String, dynamic>? authContextResponse =
        await _channel.invokeMapMethod('getAuthenticationContext', {
      'url': url,
    });

    try {
      return AuthenticationContext.mapToAuthenticationContext(
          authContextResponse);
    } on Exception {
      rethrow;
    }
  }

  /// Get all current passkeys for this device.
  ///
  /// Returns a [List] of [Passkey]s
  static Future<List<Passkey>> getPasskeys() async {
    List<dynamic>? passkeyListMap =
        await _channel.invokeListMethod("getPasskeys");
    List<Passkey> passkeyList = List.empty(growable: true);

    if (passkeyListMap != null) {
      try {
        passkeyList = passkeyListMap
            .map((passkey) => Passkey.mapToPasskey(passkey))
            .toList();
      } on Exception {
        rethrow;
      }
    } else {
      throw Exception("Error getting passkeys from platform");
    }

    return passkeyList;
  }

  /// Delete a [Passkey] by ID on current device.
  /// Note: It is possible to delete a passkey that does not exist.
  /// Warning: deleting a [Passkey] is destructive and will remove everything
  /// from the device. If no other device contains the passkey then the user
  /// will need to complete a recovery in order to log in again on this device.
  ///
  /// [id] the unique identifier of the [Passkey].
  static Future<void> deletePasskey(String id) async {
    await _channel.invokeMethod('deletePasskey', {
      'passkeyId': id,
    });
  }

  /// Returns whether a URL is a valid Bind Passkey URL or not.
  ///
  /// [url] A URL String
  static Future<bool> isBindPasskeyUrl(String url) async {
    try {
      return await _channel.invokeMethod('isBindPasskeyUrl', {'url': url});
    } on Exception {
      rethrow;
    }
  }

  /// Returns whether a URL is a valid Authenticate URL or not.
  ///
  /// [url] A URL String
  static Future<bool> isAuthenticateUrl(String url) async {
    try {
      return await _channel.invokeMethod('isAuthenticateUrl', {'url': url});
    } on Exception {
      rethrow;
    }
  }

  /// Redeems an OTP for a grant code.
  ///
  /// Returns a promise that resolves to an [AuthenticateResponse] on success
  /// or an [OtpChallengeResponse] on failure to authenticate with the provided OTP code.
  /// Use the url provided in [OtpChallengeResponse] for retry.
  ///
  /// [url] The authentication URL of the current transaction.
  /// [otp] The OTP to redeem..
  /// Returns a [AuthenticateResponse] or [OtpChallengeResponse] or throws an [Exception]
  static Future<RedeemOtpResponse> redeemOtp(String url, String otp) async {
    final Map<String, dynamic>? redeemOtpResponse =
        await _channel.invokeMapMethod('redeemOtp', {
      'url': url,
      'otp': otp,
    });

    try {
      if (redeemOtpResponse != null) {
        if (redeemOtpResponse.containsKey('redirectUrl')) {
          return RedeemOtpResponse.success(AuthenticateResponse(
            redirectUrl: redeemOtpResponse["redirectUrl"],
            message: redeemOtpResponse["message"],
            passkeyBindingToken: redeemOtpResponse["passkeyBindingToken"]
          ));
        } else if (redeemOtpResponse.containsKey('url')) {
          return RedeemOtpResponse.failedOtp(OtpChallengeResponse(
            url: redeemOtpResponse['url'],
          ));
        }
      }
      throw Exception(
          'Invalid response from redeemOtp: Neither AuthenticateResponse nor OtpChallengeResponse found.');
    } on Exception {
      rethrow;
    }
  }
}

class RedeemOtpResponse {
  final AuthenticateResponse? success;
  final OtpChallengeResponse? failedOtp;

  RedeemOtpResponse._({this.success, this.failedOtp});

  bool get isSuccess => success != null;
  bool get isFailedOtp => failedOtp != null;

  factory RedeemOtpResponse.success(AuthenticateResponse response) {
    return RedeemOtpResponse._(success: response);
  }

  factory RedeemOtpResponse.failedOtp(OtpChallengeResponse response) {
    return RedeemOtpResponse._(failedOtp: response);
  }
}

/// A response returned after successfully binding a passkey to a device.
class BindPasskeyResponse {
  /// The [Passkey] bound to the device.
  Passkey passkey;

  /// A URI that can be redirected to once a passkey is bound. This could be a URI that automatically logs the user in with the newly bound passkey, or a success page indicating that a passkey has been bound.
  String? postBindingRedirectUri;

  BindPasskeyResponse({
    required this.passkey,
    required this.postBindingRedirectUri,
  });

  String toJson() {
    return "{"
        "\"passkey\":${passkey.toJson()},"
        "\"postBindingRedirectUri\":\"$postBindingRedirectUri\"}";
  }

  @override
  String toString() {
    return "{\"BindPasskeyResponse\":${toJson()}}";
  }
}

/// A Universal Passkey is a public and private key pair. The private key is generated, stored, and never leaves the user’s devices’ hardware root of trust (i.e. Secure Enclave).
/// The public key is sent to the Beyond Identity cloud. The private key cannot be tampered with, viewed, or removed from the device in which it is created unless the user explicitly indicates that the trusted device be removed.
/// Passkeys are cryptographically linked to devices and an Identity. A single device can store multiple passkeys for different users and a single Identity can have multiple passkeys.
class Passkey {
  /// The Globally unique ID of this passkey.
  String id;

  /// The external (cloud) ID
  String passkeyId;

  /// The time when this passkey was created locally. This could be different from "created" which is the time when this passkey was created on the server.
  String localCreated;

  /// The last time when this passkey was updated locally. This could be different from "updated" which is the last time when this passkey was updated on the server.
  String localUpdated;

  /// The base url for all binding & auth requests
  String apiBaseUrl;

  /// Associated key handle.
  String keyHandle;

  /// The current state of this passkey
  PasskeyState state;

  /// The time this passkey was created.
  String created;

  /// The last time this passkey was updated.
  String updated;

  /// Tenant information associated with this passkey.
  PasskeyTenant tenant;

  /// Realm information associated with this passkey.
  PasskeyRealm realm;

  /// Identity information associated with this passkey.
  PasskeyIdentity identity;

  /// Theme information associated with this passkey
  PasskeyTheme theme;

  Passkey({
    required this.id,
    required this.passkeyId,
    required this.localCreated,
    required this.localUpdated,
    required this.apiBaseUrl,
    required this.keyHandle,
    required this.state,
    required this.created,
    required this.updated,
    required this.tenant,
    required this.realm,
    required this.identity,
    required this.theme,
  });

  static Passkey mapToPasskey(dynamic passkey) {
    return Passkey(
      id: passkey["id"],
      passkeyId: passkey["passkeyId"],
      localCreated: passkey["localCreated"],
      localUpdated: passkey["localUpdated"],
      apiBaseUrl: passkey["apiBaseUrl"],
      keyHandle: passkey["keyHandle"],
      state: PasskeyStateHelper.fromString(passkey["state"]),
      created: passkey["created"],
      updated: passkey["updated"],
      tenant: PasskeyTenant.mapToTenant(passkey["tenant"]),
      realm: PasskeyRealm.mapToRealm(passkey["realm"]),
      identity: PasskeyIdentity.mapToIdentity(passkey["identity"]),
      theme: PasskeyTheme.mapToTheme(passkey["theme"]),
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"passkeyId\":\"$passkeyId\","
        "\"localCreated\":\"$localCreated\","
        "\"localUpdated\":\"$localUpdated\","
        "\"apiBaseUrl\":\"$apiBaseUrl\","
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
    return "{\"Passkey\":${toJson()}}";
  }
}

/// State of a given [Passkey]
enum PasskeyState {
  /// [Passkey] is active
  // ignore: constant_identifier_names
  ACTIVE,

  /// [Passkey] is revoked
  // ignore: constant_identifier_names
  REVOKED,
}

class PasskeyStateHelper {
  static PasskeyState fromString(String state) {
    switch (state.toLowerCase()) {
      case "active":
        return PasskeyState.ACTIVE;
      case "revoked":
        return PasskeyState.REVOKED;
      default:
        throw Exception(
            "Cannot initialize PasskeyState from invalid String value $state");
    }
  }
}

/// Tenant information associated with a [Passkey]. A Tenant represents an organization in the Beyond Identity Cloud and serves as a root container for all other cloud components in your configuration.
class PasskeyTenant {
  /// The unique identifier of the tenant.
  String id;

  /// The display name of the tenant.
  String displayName;

  PasskeyTenant({
    required this.id,
    required this.displayName,
  });

  static PasskeyTenant mapToTenant(dynamic passkey) {
    return PasskeyTenant(
      id: passkey["id"],
      displayName: passkey["displayName"],
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"displayName\":\"$displayName\"}";
  }

  @override
  String toString() {
    return "{\"Tenant\":${toJson()}}";
  }
}

/// Realm information associated with a [Passkey].
/// A Realm is a unique administrative domain within a `Tenant`.
/// Some Tenants will only need the use of a single Realm, in this case a Realm and a Tenant may seem synonymous.
/// Each Realm contains a unique set of Directory, Policy, Event, Application, and Branding objects.
class PasskeyRealm {
  /// The unique identifier of the realm.
  String id;

  /// The display name of the realm.
  String displayName;

  PasskeyRealm({
    required this.id,
    required this.displayName,
  });

  static PasskeyRealm mapToRealm(dynamic passkey) {
    return PasskeyRealm(
      id: passkey["id"],
      displayName: passkey["displayName"],
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"displayName\":\"$displayName\"}";
  }

  @override
  String toString() {
    return "{\"Realm\":${toJson()}}";
  }
}

/// Identity information associated with a [Passkey].
/// An Identity is a unique identifier that may be used by an end-user to gain access governed by Beyond Identity.
/// An Identity is created at the Realm level.
/// An end-user may have multiple identities. A Realm can have many Identities.
class PasskeyIdentity {
  /// The unique identifier of the identity.
  String id;

  /// The display name of the identity.
  String displayName;

  /// The username of the identity.
  String username;

  /// The primary email address of the identity.
  String? primaryEmailAddress;

  PasskeyIdentity({
    required this.id,
    required this.displayName,
    required this.username,
    required this.primaryEmailAddress,
  });

  static PasskeyIdentity mapToIdentity(dynamic passkey) {
    return PasskeyIdentity(
      id: passkey["id"],
      displayName: passkey["displayName"],
      username: passkey["username"],
      primaryEmailAddress: passkey["primaryEmailAddress"],
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"displayName\":\"$displayName\","
        "\"username\":\"$username\","
        "\"primaryEmailAddress\":\"$primaryEmailAddress\"}";
  }

  @override
  String toString() {
    return "{\"Identity\":${toJson()}}";
  }
}

/// Theme associated with a [Passkey].
class PasskeyTheme {
  /// URL to for resolving the logo image for light mode.
  String logoLightUrl;

  /// URL to for resolving the logo image for dark mode.
  String logoDarkUrl;

  /// URL for customer support portal.
  String supportUrl;

  PasskeyTheme({
    required this.logoLightUrl,
    required this.logoDarkUrl,
    required this.supportUrl,
  });

  static PasskeyTheme mapToTheme(dynamic passkey) {
    return PasskeyTheme(
      logoLightUrl: passkey["logoLightUrl"],
      logoDarkUrl: passkey["logoDarkUrl"],
      supportUrl: passkey["supportUrl"],
    );
  }

  String toJson() {
    return "{"
        "\"logoLightUrl\":\"$logoLightUrl\","
        "\"logoDarkUrl\":\"$logoDarkUrl\","
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
  String? message;

  /// An optional one-time-token returned from successful `redeemOtp` that may be redeemed for a credential_binding_link from the /credential-binding-jobs endpoint.
  String? passkeyBindingToken;

  AuthenticateResponse({
    required this.redirectUrl,
    required this.message,
    required this.passkeyBindingToken
  });

  String toJson() {
    return "{"
        "\"redirectUrl\":\"$redirectUrl\","
        "\"message\":\"$message\","
        "\"passkeyBindingToken\":\"$passkeyBindingToken\"}";
  }

  @override
  String toString() {
    return "{\"AuthenticateResponse\":${toJson()}}";
  }
}

/// Information associated with the current authentication request.
///
/// Note that the `authUrl` field may differ from the URL passed into
/// `getAuthenticationContext`. In this event, the new `authUrl` must be
/// passed into `authenticate` or `authenticateOtp`, rather than the
/// original URL.
class AuthenticationContext {
  /// A URL containing the state of the current authentication transaction.
  String authUrl;

  /// The authenticating application information
  AuthenticationContextApplication application;

  /// The authenticating request origin information
  AuthenticationContextOrigin origin;

  AuthenticationContext({
    required this.authUrl,
    required this.application,
    required this.origin,
  });

  static AuthenticationContext mapToAuthenticationContext(dynamic authContext) {
    return AuthenticationContext(
        authUrl: authContext["authUrl"],
        application: AuthenticationContextApplication.mapToApplication(
            authContext["application"]),
        origin: AuthenticationContextOrigin.mapToOrigin(authContext["origin"]));
  }

  String toJson() {
    return "{"
        "\"authUrl\":\"$authUrl\","
        "\"application\":\"$application\","
        "\"origin\":\"$origin\"}";
  }

  @override
  String toString() {
    return "{\"AuthenticationContext\":${toJson()}}";
  }
}

class AuthenticationContextApplication {
  String id;
  String? displayName;

  AuthenticationContextApplication({
    required this.id,
    this.displayName,
  });

  static AuthenticationContextApplication mapToApplication(
      dynamic application) {
    return AuthenticationContextApplication(
      id: application["id"],
      displayName: application["displayName"],
    );
  }

  String toJson() {
    return "{"
        "\"id\":\"$id\","
        "\"displayName\":\"$displayName\"}";
  }

  @override
  String toString() {
    return "{\"Application\":${toJson()}}";
  }
}

class AuthenticationContextOrigin {
  String? sourceIp;
  String? userAgent;
  String? geolocation;
  String? referer;

  AuthenticationContextOrigin({
    this.sourceIp,
    this.userAgent,
    this.geolocation,
    this.referer,
  });

  static AuthenticationContextOrigin mapToOrigin(dynamic origin) {
    return AuthenticationContextOrigin(
      sourceIp: origin["sourceIp"],
      userAgent: origin["userAgent"],
      geolocation: origin["geolocation"],
      referer: origin["referer"],
    );
  }

  String toJson() {
    return "{"
        "\"sourceIp\":\"$sourceIp\","
        "\"userAgent\":\"$userAgent\","
        "\"geolocation\":\"$geolocation\","
        "\"referer\":\"$referer\"}";
  }

  @override
  String toString() {
    return "{\"Origin\":${toJson()}}";
  }
}

/// A response returned if the SDK requires an OTP.
class OtpChallengeResponse {
  /// A URL containing the state of the current authentication transaction.
  /// This should be used in the next `redeemOtp` or `authenticateOtp` function.
  String url;

  OtpChallengeResponse({
    required this.url,
  });

  String toJson() {
    return "{" "\"url\":\"$url\"}";
  }

  @override
  String toString() {
    return "{\"OtpChallengeResponse\":${toJson()}}";
  }
}
