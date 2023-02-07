import 'dart:async';
import 'dart:convert';

import 'package:bi_sdk_flutter/embeddedsdk.dart';
import 'package:bi_sdk_flutter/print.dart';
import 'package:embeddedsdk_example/config.dart';
import 'package:embeddedsdk_example/extensions.dart';
import 'package:embeddedsdk_example/simple_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:pkce/pkce.dart';
import 'package:url_launcher/url_launcher.dart';

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    biDebugPrint(data.toString());
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    biDebugPrint(data.toString());
    return data;
  }
}

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _registerUserController = TextEditingController();
  String _registerUserText = '';
  String _registerUserResultText = '';

  final _recoverUserController = TextEditingController();
  String _recoverUserText = '';
  String _recoverUserResultText = '';

  final _bindController = TextEditingController();
  String _bindText = '';
  String _bindResultText = '';

  String _authBeyondIdentityResultText = '';

  String _authOktaResultText = '';

  String _authAuth0ResultText = '';

  final _authController = TextEditingController();
  String _authText = '';
  String _authResultText = '';

  final _bindUrlController = TextEditingController();
  String _bindUrlText = '';
  String _bindUrlResultText = '';

  final _authUrlController = TextEditingController();
  String _authUrlText = '';
  String _authUrlResultText = '';

  String _getPasskeysResultText = '';

  final _deletePasskeyController = TextEditingController();
  String _deletePasskeyText = '';
  String _deletePasskeyResultText = '';

  @override
  void initState() {
    super.initState();
    EmbeddedSdk.initialize("Gimmie your biometrics",
        logger: EmbeddedSdk.enableLogger());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _registerDemoUser() async {
    String registerUserText = _registerUserText;
    String registerUserResultText = '';

    http.Client client =
        InterceptedClient.build(interceptors: [LoggingInterceptor()]);

    try {
      var response = await client.post(
        Uri.parse("https://acme-cloud.byndid.com/credential-binding-link"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': _registerUserController.text,
          'authenticator_type': 'native',
          'delivery_method': 'return',
        }),
      );

      Map responseBody = json.decode(response.body);

      if (!responseBody.containsKey('credential_binding_link')) {
        registerUserResultText = jsonPrettyPrint(response.body);
      } else {
        try {
          BindPasskeyResponse bindPasskeyResponse =
              await EmbeddedSdk.bindPasskey(
                  responseBody['credential_binding_link']);
          registerUserText = '';
          registerUserResultText = jsonPrettyPrint(bindPasskeyResponse.toString());
        } on PlatformException catch (e) {
          errorPrint(e);
          registerUserResultText = "could not register passkey $e";
        } catch (e) {
          errorPrint(e);
          registerUserResultText = "${e.runtimeType} registering passkey = $e";
        }
      }
    } catch (e) {
      errorPrint(e);
      registerUserResultText = "${e.runtimeType} registering passkey = $e";
    } finally {
      client.close();
    }

    setState(() {
      _registerUserText = registerUserText;
      _registerUserResultText = registerUserResultText;
    });
  }

  void _recoverDemoUser() async {
    String recoverUserText = _recoverUserText;
    String recoverUserResultText = '';

    http.Client client =
        InterceptedClient.build(interceptors: [LoggingInterceptor()]);

    try {
      var response = await client.post(
        Uri.parse("https://acme-cloud.byndid.com/recover-credential-binding-link"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': _recoverUserController.text,
          'authenticator_type': 'native',
          'delivery_method': 'return',
        }),
      );

      Map responseBody = json.decode(response.body);

      if (!responseBody.containsKey('credential_binding_link')) {
        recoverUserResultText = jsonPrettyPrint(response.body);
      } else {
        try {
          BindPasskeyResponse bindPasskeyResponse =
              await EmbeddedSdk.bindPasskey(
                  responseBody['credential_binding_link']);
          recoverUserText = '';
          recoverUserResultText = jsonPrettyPrint(bindPasskeyResponse.toString());
        } on PlatformException catch (e) {
          errorPrint(e);
          recoverUserResultText = "could not recover passkey $e";
        } catch (e) {
          errorPrint(e);
          recoverUserResultText = "${e.runtimeType} recovering passkey = $e";
        }
      }
    } catch (e) {
      errorPrint(e);
      recoverUserResultText = "${e.runtimeType} recovering passkey = $e";
    } finally {
      client.close();
    }

    setState(() {
      _recoverUserText = recoverUserText;
      _recoverUserResultText = recoverUserResultText;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _bind() async {
    String bindText = _bindText;
    String bindResultText = '';

    try {
      BindPasskeyResponse bindPasskeyResponse =
          await EmbeddedSdk.bindPasskey(_bindController.text);
      bindText = '';
      bindResultText = jsonPrettyPrint(bindPasskeyResponse.toString());
    } on PlatformException catch (e) {
      errorPrint(e);
      bindResultText = "could not bind passkey $e";
    } catch (e) {
      errorPrint(e);
      bindResultText = "${e.runtimeType} binding passkey = $e";
    }

    if (!mounted) return;

    setState(() {
      _bindText = bindText;
      _bindResultText = bindResultText;
    });
  }

  Future<void> onSelectPasskey(Function(String) onSelectedPasskey) async {
    try {
      List<Passkey> passkeys = await EmbeddedSdk.getPasskeys();

      if (passkeys.isEmpty) {
        onSelectedPasskey("");
      } else if (passkeys.length == 1) {
        onSelectedPasskey(passkeys.first.id);
      } else {
        List<Widget> widgets = List.empty(growable: true);

        for (Passkey passkey in passkeys) {
          widgets.add(SimpleDialogItem(
            key: Key(passkey.id),
            text: passkey.identity.displayName,
            onPressed: () {
              Navigator.pop(context, passkey.id);
              onSelectedPasskey(passkey.id);
            },
          ));
        }

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: const Text('Select account'),
              children: widgets,
            );
          }
        );
      }
    } on PlatformException catch (e) {
      errorPrint(e);
      rethrow;
    } catch (e) {
      errorPrint(e);
      rethrow;
    }
  }

  Future<void> _authenticateBeyondIdentity() async {
    updateAuthResultText(authResultText) async {
      if (!mounted) return;

      setState(() {
        _authBeyondIdentityResultText = authResultText;
      });
    }

    try {
      onSelectPasskey((passkeyId) async {
        final pkcePair = PkcePair.generate();

        http.Client client =
            InterceptedClient.build(interceptors: [LoggingInterceptor()]);

        // Present the dialog to the user
        var response = await client.get(
          Uri.parse(
            "https://auth-us.beyondidentity.com/v1/tenants/00012da391ea206d/realms/862e4b72cfdce072/applications/a8c0aa60-38e4-42b6-bd52-ef64aba5478b/authorize"
            "?state=state"
            "&scope=openid"
            "&response_type=code"
            "&redirect_uri=${Uri.encodeComponent("acme://")}"
            "&code_challenge_method=S256"
            "&code_challenge=${pkcePair.codeChallenge}"
            "&client_id=KhSWSmfhZ6xCMz9yw7DpJcv5",
          ),
        );

        Map responseBody = json.decode(response.body);

        if (!responseBody.containsKey('authenticate_url')) {
          updateAuthResultText(jsonPrettyPrint(response.body));
        } else {
          _embeddedSdkAuthenticate(
            responseBody['authenticate_url'],
            passkeyId,
            updateAuthResultText,
            (redirectResponse) async {
              http.Client client =
                  InterceptedClient.build(interceptors: [LoggingInterceptor()]);

              try {
                var response = await client.post(
                  Uri.parse(
                      "https://auth-us.beyondidentity.com/v1/tenants/00012da391ea206d/realms/862e4b72cfdce072/applications/a8c0aa60-38e4-42b6-bd52-ef64aba5478b/token"),
                  headers: <String, String>{
                    'Content-Type':
                        'application/x-www-form-urlencoded; charset=UTF-8',
                  },
                  body: {
                    'client_id': 'KhSWSmfhZ6xCMz9yw7DpJcv5',
                    'code': Uri.parse(redirectResponse).queryParameters['code'],
                    'code_verifier': pkcePair.codeVerifier,
                    'grant_type': 'authorization_code',
                    'redirect_uri': 'acme://',
                    'state': 'state',
                  },
                );

                updateAuthResultText(jsonPrettyPrint(response.body));
              } catch (e) {
                errorPrint(e);
                updateAuthResultText("${e.runtimeType} authenticating = $e");
              } finally {
                client.close();
              }
            },
            shouldReturnNonRedirectUrl: false,
          );
        }
      });
    } on PlatformException catch (e) {
      errorPrint(e);
      updateAuthResultText("could not authenticate $e");
    } catch (e) {
      errorPrint(e);
      updateAuthResultText("${e.runtimeType} authenticating = $e");
    }
  }

  Future<void> _authenticateOkta() async {
    updateAuthResultText(authResultText) async {
      if (!mounted) return;

      setState(() {
        _authOktaResultText = authResultText;
      });
    }

    try {
      onSelectPasskey((passkeyId) async {
        final pkcePair = PkcePair.generate();

        // Present the dialog to the user
        var oktaResult = await FlutterWebAuth.authenticate(
          url: "https://dev-43409302.okta.com/oauth2/v1/authorize"
              "?idp=0oa5rswruxTaPUcgl5d7"
              "&scope=openid"
              "&response_type=code"
              "&state=state"
              "&code_challenge_method=S256"
              "&redirect_uri=${Uri.encodeComponent("acme://okta")}"
              "&nonce=nonce"
              "&code_challenge=${pkcePair.codeChallenge}"
              "&client_id=0oa5kipb8rdo4WCkf5d7",
          callbackUrlScheme: "acme",
        );

        _embeddedSdkAuthenticate(
          oktaResult,
          passkeyId,
          updateAuthResultText,
          (redirectResponse) async {
            http.Client client =
                InterceptedClient.build(interceptors: [LoggingInterceptor()]);

            try {
              var response = await client.post(
                Uri.parse("https://dev-43409302.okta.com/oauth2/v1/token"),
                headers: <String, String>{
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                },
                body: {
                  'client_id': '0oa5kipb8rdo4WCkf5d7',
                  'code': Uri.parse(redirectResponse).queryParameters['code'],
                  'code_verifier': pkcePair.codeVerifier,
                  'grant_type': 'authorization_code',
                  'redirect_uri': 'acme://okta',
                },
              );

              updateAuthResultText(jsonPrettyPrint(response.body));
            } catch (e) {
              errorPrint(e);
              updateAuthResultText("${e.runtimeType} authenticating = $e");
            } finally {
              client.close();
            }
          },
          shouldReturnNonAuthenticateUrl: true,
        );
      });
    } on PlatformException catch (e) {
      errorPrint(e);
      updateAuthResultText("could not authenticate $e");
    } catch (e) {
      errorPrint(e);
      updateAuthResultText("${e.runtimeType} authenticating = $e");
    }
  }

  Future<void> _authenticateAuth0() async {
    updateAuthResultText(authResultText) async {
      if (!mounted) return;

      setState(() {
        _authAuth0ResultText = authResultText;
      });
    }

    try {
      onSelectPasskey((passkeyId) async {
        final pkcePair = PkcePair.generate();

        // Present the dialog to the user
        var auth0Result = await FlutterWebAuth.authenticate(
          url: "https://dev-pt10fbkg.us.auth0.com/authorize"
              "?connection=Example-App-Native"
              "&scope=openid"
              "&response_type=code"
              "&state=state"
              "&code_challenge_method=S256"
              "&redirect_uri=${Uri.encodeComponent("acme://auth0")}"
              "&nonce=nonce"
              "&code_challenge=${pkcePair.codeChallenge}"
              "&client_id=q1cubQfeZWnajq5YkeZVD3NauRqU4vNs",
          callbackUrlScheme: "acme",
        );

        _embeddedSdkAuthenticate(
          auth0Result,
          passkeyId,
          updateAuthResultText,
          (redirectResponse) async {
            http.Client client =
                InterceptedClient.build(interceptors: [LoggingInterceptor()]);

            try {
              var response = await client.post(
                Uri.parse("https://dev-pt10fbkg.us.auth0.com/oauth/token"),
                headers: <String, String>{
                  'Content-Type':
                      'application/x-www-form-urlencoded; charset=UTF-8',
                },
                body: {
                  'grant_type': 'authorization_code',
                  'client_id': 'q1cubQfeZWnajq5YkeZVD3NauRqU4vNs',
                  'code': Uri.parse(redirectResponse).queryParameters['code'],
                  'code_verifier': pkcePair.codeVerifier,
                  'redirect_uri': 'acme://auth0',
                },
              );

              updateAuthResultText(jsonPrettyPrint(response.body));
            } catch (e) {
              errorPrint(e);
              updateAuthResultText("${e.runtimeType} authenticating = $e");
            } finally {
              client.close();
            }
          },
        );
      });
    } on PlatformException catch (e) {
      errorPrint(e);
      updateAuthResultText("could not authenticate $e");
    } catch (e) {
      errorPrint(e);
      updateAuthResultText("${e.runtimeType} authenticating = $e");
    }
  }

  /// Function to standardize behavior of authentication.
  ///
  /// [url] url parameter for [EmbeddedSdk.authenticate].
  /// [passkeyId] passkeyId parameter for [EmbeddedSdk.authenticate].
  /// [onAuthenticateResponse] callback to handle response from [EmbeddedSdk.authenticate].
  /// [onRedirectResponse] callback to handle url from [AuthenticateResponse].
  /// [shouldReturnNonRedirectUrl] Optional flag to return redirectUrl or
  /// the url from following the redirectUrl. Example: Beyond Identity.
  /// [shouldReturnNonAuthenticateUrl] Optional flag to return original url if
  /// it is not an authenticate url. Example: Okta.
  Future<void> _embeddedSdkAuthenticate(
    String url,
    String passkeyId,
    Function(String) onAuthenticateResponse,
    Function(String) onRedirectResponse, {
    bool shouldReturnNonRedirectUrl = true,
    bool shouldReturnNonAuthenticateUrl = false,
  }) async {
    try {
      if (await EmbeddedSdk.isAuthenticateUrl(url)) {
        // Extract token from resulting url
        var authenticateResponse =
            await EmbeddedSdk.authenticate(url, passkeyId);
        onAuthenticateResponse(
          jsonPrettyPrint(authenticateResponse.toString()),
        );

        // Present the dialog to the user
        if (shouldReturnNonRedirectUrl) {
          onRedirectResponse(await FlutterWebAuth.authenticate(
            url: authenticateResponse.redirectUrl,
            callbackUrlScheme: "acme",
          ));
        } else {
          onRedirectResponse(authenticateResponse.redirectUrl);
        }
      } else {
        if (shouldReturnNonAuthenticateUrl) {
          onRedirectResponse(url);
        }
      }
    } on PlatformException catch (e) {
      errorPrint(e);
      onAuthenticateResponse("could not authenticate $e");
    } catch (e) {
      errorPrint(e);
      onAuthenticateResponse("${e.runtimeType} authenticating = $e");
    }
  }

  Future<void> _authenticate() async {
    String authText = _authText;
    String authResultText = '';

    try {
      onSelectPasskey((passkeyId) async {
        AuthenticateResponse authenticateResponse =
            await EmbeddedSdk.authenticate(_authController.text, passkeyId);
        authText = '';
        authResultText = jsonPrettyPrint(authenticateResponse.toString());
      });
    } on PlatformException catch (e) {
      errorPrint(e);
      authResultText = "could not authenticate $e";
    } catch (e) {
      errorPrint(e);
      authResultText = "${e.runtimeType} authenticating = $e";
    }

    if (!mounted) return;

    setState(() {
      _authText = authText;
      _authResultText = authResultText;
    });
  }

  Future<void> _getPasskeys() async {
    String getPasskeysResultText = '';

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      List<Passkey> passkeys = await EmbeddedSdk.getPasskeys();
      getPasskeysResultText = "Passkeys = ${jsonPrettyPrintPasskeys(passkeys)}";
    } on PlatformException catch (e) {
      errorPrint(e);
      getPasskeysResultText = "could not get passkeys $e";
    } catch (e) {
      errorPrint(e);
      getPasskeysResultText = "${e.runtimeType} getting passkeys = $e";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _getPasskeysResultText = getPasskeysResultText;
    });
  }

  Future<void> _deletePasskey() async {
    String deletePasskeyText = _deletePasskeyText;
    String deletePasskeyResultText = '';

    try {
      if (_deletePasskeyController.text.isNotEmpty) {
        await EmbeddedSdk.deletePasskey(_deletePasskeyController.text);
        deletePasskeyText = '';
        deletePasskeyResultText = "Deleted passkey ${_deletePasskeyController.text}";
      } else {
        List<Passkey> passkeys = await EmbeddedSdk.getPasskeys();
        if (passkeys.isNotEmpty) {
          await EmbeddedSdk.deletePasskey(passkeys.first.id);
          deletePasskeyText = '';
          deletePasskeyResultText = "Deleted passkey ${passkeys.first.id}";
        } else {
          deletePasskeyText = '';
          deletePasskeyResultText = "No passkeys to delete";
        }
      }
    } on PlatformException catch (e) {
      errorPrint(e);
      deletePasskeyResultText = "could not delete passkey $e";
    } catch (e) {
      errorPrint(e);
      deletePasskeyResultText = "${e.runtimeType} deleting passkey = $e";
    }

    if (!mounted) return;

    setState(() {
      _deletePasskeyText = deletePasskeyText;
      _deletePasskeyResultText = deletePasskeyResultText;
    });
  }

  Future<void> _bindUrl() async {
    String bindUrlText = _bindUrlText;
    String bindUrlResultText = '';

    try {
      bool isBindUrl =
          await EmbeddedSdk.isBindPasskeyUrl(_bindUrlController.text);
      bindUrlText = '';
      bindUrlResultText = isBindUrl.toString();
    } on PlatformException catch (e) {
      errorPrint(e);
      bindUrlResultText = "could not validate bind passkey url $e";
    } catch (e) {
      errorPrint(e);
      bindUrlResultText = "${e.runtimeType} validating = $e";
    }

    if (!mounted) return;

    setState(() {
      _bindUrlText = bindUrlText;
      _bindUrlResultText = bindUrlResultText;
    });
  }

  Future<void> _authenticateUrl() async {
    String authUrlText = _authUrlText;
    String authUrlResultText = '';

    try {
      bool isAuthUrl =
          await EmbeddedSdk.isAuthenticateUrl(_authUrlController.text);
      authUrlText = '';
      authUrlResultText = isAuthUrl.toString();
    } on PlatformException catch (e) {
      errorPrint(e);
      authUrlResultText = "could not validate authenticate url $e";
    } catch (e) {
      errorPrint(e);
      authUrlResultText = "${e.runtimeType} validating = $e";
    }

    if (!mounted) return;

    setState(() {
      _authUrlText = authUrlText;
      _authUrlResultText = authUrlResultText;
    });
  }

  Future<void> _viewDeveloperDocs() async {
    _launchUrl("https://developer.beyondidentity.com/docs/v1/sdks/kotlin-sdk/overview");
  }

  Future<void> _visitSupport() async {
    _launchUrl("https://join.slack.com/t/byndid/shared_invite/zt-1anns8n83-NQX4JvW7coi9dksADxgeBQ");
  }

  Future<void> _launchUrl(String url) async {
    var uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $uri';
    }
  }

  String jsonPrettyPrint(String string) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json.decode(string));
    } catch (e) {
      return string;
    }
  }

  String jsonPrettyPrintPasskey(Passkey passkey) {
    return jsonPrettyPrint(passkey.toJson());
  }

  String jsonPrettyPrintPasskeys(List<Passkey> passkeys) {
    try {
      var string = "";
      string += "[";
      for (int i = 0; i < passkeys.length; i++) {
        Passkey passkey = passkeys[i];
        if (i == passkeys.length - 1) {
          string += passkey.toJson();
        } else {
          string += "${passkey.toJson()},";
        }
      }
      string += "]";
      return jsonPrettyPrint(string);
    } catch (e) {
      return e.toString();
    }
  }

  void errorPrint(Object e) {
    biDebugPrint("${e.runtimeType} = $e");
  }

  ///////////////////////////////////////////////////
  ///////////////// UI //////////////////////////////
  ///////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Embedded SDK example app'),
        ),
        body: Container(
          color: Colors.grey[300],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                _card([
                  _title("\nEmbedded SDK Functionality"),
                  _description("SDK Version: ${BuildConfig.SDK_VERSION.capitalize()}", paddingTop: 8.0, paddingBottom: 0.0),
                  _description("Environment: ${BuildConfig.ENVIRONMENT.capitalize()}", paddingTop: 0.0, paddingBottom: 8.0),
                ]),
                _card([
                  _title("\nGet Started"),
                  _subTitle("Bind Passkey"),
                  _description("To get started with using our embedded SDK sample app, enter any username to bind a passkey to this device."),
                  _buttonInputTextGroup("Bind Passkey", "Username", _registerUserController, _registerDemoUser, _registerUserText),
                  Text(_registerUserResultText),
                  _subTitle("Recover Passkey"),
                  _description("If you have an account with a passkey you can’t access anymore, enter your username to recover your account and bind a passkey to this device."),
                  _buttonInputTextGroup("Recover Passkey", "Username", _recoverUserController, _recoverDemoUser, _recoverUserText),
                  Text(_recoverUserResultText),
                ]),
                _card([
                  _title("\nBind Passkey"),
                  _description("Paste the Bind Passkey URL you received in your email or generated through the API in order to bind a passkey."),
                  _buttonInputTextGroup("Bind Passkey", "Bind Passkey URL", _bindController, _bind, _bindText),
                  Text(_bindResultText),
                ]),
                _card([
                  _title("\nAuthenticate"),
                  _description("Authenticate against a passkey bound to this device. If more than one passkey is present, you must select a passkey during authentication."),
                  _subTitle("Authenticate with Beyond Identity"),
                  _description("Try authenticating with Beyond Identity as the primary IdP."),
                  _buttonTextGroup("Authenticate with Beyond Identity", _authenticateBeyondIdentity, _authBeyondIdentityResultText),
                  _subTitle("Authenticate with Okta (Web)"),
                  _description("Try authenticating with Okta using Beyond Identity as a secondary IdP."),
                  _buttonTextGroup("Authenticate with Okta", _authenticateOkta, _authOktaResultText),
                  _subTitle("Authenticate with Auth0 (Web)"),
                  _description("Try authenticating with Auth0 using Beyond Identity as a secondary IdP."),
                  _buttonTextGroup("Authenticate with Auth0", _authenticateAuth0, _authAuth0ResultText),
                ]),
                _card([
                  _title("\nAuthenticate"),
                  _description("Authenticate against a passkey bound to this device. If more than one passkey is present, you must select a passkey during authentication."),
                  _buttonInputTextGroup("Authenticate", "Authenticate URL", _authController, _authenticate, _authText),
                  Text(_authResultText),
                ]),
                _card([
                  _title("\nPasskey Management"),
                  _subTitle("View Passkey"),
                  _description("View details of your passkey, such as date created, identity and other information related to your device."),
                  _buttonTextGroup("Get Passkeys", _getPasskeys, _getPasskeysResultText),
                  _subTitle("Delete Passkey"),
                  _description("Delete your passkey on your device."),
                  _buttonInputTextGroup("Delete Passkey", "Passkey ID", _deletePasskeyController, _deletePasskey, _deletePasskeyText),
                  Text(_deletePasskeyResultText),
                ]),
                _card([
                  _title("\nURL Validation"),
                  _subTitle("Bind Passkey URL"),
                  _description("Paste a Url here to validate if it's a bind passkey url."),
                  _buttonInputTextGroup("Validate URL", "Bind Passkey URL", _bindUrlController, _bindUrl, _bindUrlText),
                  Text(_bindUrlResultText),
                  _subTitle("Authenticate URL"),
                  _description("Paste a Url here to validate if it's an authenticate url."),
                  _buttonInputTextGroup("Validate URL", "Authenticate URL", _authUrlController, _authenticateUrl, _authUrlText),
                  Text(_authUrlResultText),
                ]),
                _card([
                  _title("\nQuestions or issues?"),
                  _description("Read through our developer docs for more details on our embedded SDK or reach out to support."),
                  _buttonGroup("View Developer Docs", _viewDeveloperDocs),
                  _buttonGroup("Visit Support", _visitSupport),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> widgets) {
    return Card(
      child: _paddingAll(
        Column(
          children: widgets,
        ),
        padding: 16,
      ),
    );
  }

  Widget _title(
    String titleText, {
    double paddingLeft = 0.0,
    double paddingTop = 0.0,
    double paddingRight = 0.0,
    double paddingBottom = 12.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        _paddingFromLTRB(
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          paddingLeft: paddingLeft,
          paddingTop: paddingTop,
          paddingRight: paddingRight,
          paddingBottom: paddingBottom,
        ),
      ],
    );
  }

  Widget _subTitle(
    String subTitleText, {
    double paddingLeft = 0.0,
    double paddingTop = 10.0,
    double paddingRight = 0.0,
    double paddingBottom = 10.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: _paddingFromLTRB(
            Text(
              subTitleText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            paddingLeft: paddingLeft,
            paddingTop: paddingTop,
            paddingRight: paddingRight,
            paddingBottom: paddingBottom,
          ),
        ),
      ],
    );
  }

  Widget _description(
    String description, {
    double paddingLeft = 0.0,
    double paddingTop = 8.0,
    double paddingRight = 0.0,
    double paddingBottom = 8.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: _paddingFromLTRB(
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            paddingLeft: paddingLeft,
            paddingTop: paddingTop,
            paddingRight: paddingRight,
            paddingBottom: paddingBottom,
          ),
        ),
      ],
    );
  }

  Widget _buttonGroup(
    String buttonLabel,
    VoidCallback callback,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          child: Text(buttonLabel),
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size.fromWidth(double.maxFinite),
          ),
        ),
      ],
    );
  }

  Widget _buttonTextGroup(
    String buttonLabel,
    VoidCallback callback,
    String text,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          child: Text(buttonLabel),
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size.fromWidth(double.maxFinite),
          ),
        ),
        SelectableText(text),
      ],
    );
  }

  Widget _buttonInputTextGroup(
    String buttonLabel,
    String inputLabel,
    TextEditingController controller,
    VoidCallback callback,
    String text,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        ElevatedButton(
          child: Text(buttonLabel),
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size.fromWidth(double.maxFinite),
          ),
        ),
        TextFormField(
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            labelText: inputLabel,
          ),
          controller: controller,
        ),
        SelectableText("\n$text"),
      ],
    );
  }

  Widget _paddingAll(
    Widget widget, {
    double padding = 16.0,
  }) {
    return Padding(
      padding: EdgeInsets.all(
        padding,
      ),
      child: widget,
    );
  }

  Widget _paddingFromLTRB(
    Widget widget, {
    double paddingLeft = 0.0,
    double paddingTop = 4.0,
    double paddingRight = 0.0,
    double paddingBottom = 4.0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        paddingLeft,
        paddingTop,
        paddingRight,
        paddingBottom,
      ),
      child: widget,
    );
  }
}
