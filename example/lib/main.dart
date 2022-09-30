import 'dart:async';
import 'dart:convert';

import 'package:bi_sdk_flutter/embeddedsdk.dart';
import 'package:bi_sdk_flutter/simple_dialog.dart';
import 'package:embeddedsdk_example/config.dart';
import 'package:embeddedsdk_example/extensions.dart';
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
    print(data.toString());
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    print(data.toString());
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
  final bool _enableLogging = true;

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

  String _getCredentialsResultText = '';

  final _deleteCredentialController = TextEditingController();
  String _deleteCredentialText = '';
  String _deleteCredentialResultText = '';

  @override
  void initState() {
    super.initState();
    Embeddedsdk.initialize("Gimmie your biometrics", _enableLogging);
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
          BindCredentialResponse bindCredentialResponse =
              await Embeddedsdk.bindCredential(
                  responseBody['credential_binding_link']);
          registerUserText = '';
          registerUserResultText = jsonPrettyPrint(bindCredentialResponse.toString());
        } on PlatformException catch (e) {
          errorPrint(e);
          registerUserResultText = "could not register credential $e";
        } catch (e) {
          errorPrint(e);
          registerUserResultText = "${e.runtimeType} registering credential = $e";
        }
      }
    } catch (e) {
      errorPrint(e);
      registerUserResultText = "${e.runtimeType} registering credential = $e";
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
          BindCredentialResponse bindCredentialResponse =
              await Embeddedsdk.bindCredential(
                  responseBody['credential_binding_link']);
          recoverUserText = '';
          recoverUserResultText = jsonPrettyPrint(bindCredentialResponse.toString());
        } on PlatformException catch (e) {
          errorPrint(e);
          recoverUserResultText = "could not recover credential $e";
        } catch (e) {
          errorPrint(e);
          recoverUserResultText = "${e.runtimeType} recovering credential = $e";
        }
      }
    } catch (e) {
      errorPrint(e);
      recoverUserResultText = "${e.runtimeType} recovering credential = $e";
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
      BindCredentialResponse bindCredentialResponse =
          await Embeddedsdk.bindCredential(_bindController.text);
      bindText = '';
      bindResultText = jsonPrettyPrint(bindCredentialResponse.toString());
    } on PlatformException catch (e) {
      errorPrint(e);
      bindResultText = "could not bind credential $e";
    } catch (e) {
      errorPrint(e);
      bindResultText = "${e.runtimeType} binding credential = $e";
    }

    if (!mounted) return;

    setState(() {
      _bindText = bindText;
      _bindResultText = bindResultText;
    });
  }

  Future<void> onSelectCredential(Function(String) onSelectedCredential) async {
    try {
      List<Credential> credentials = await Embeddedsdk.getCredentials();

      if (credentials.isEmpty) {
        onSelectedCredential("");
      } else if (credentials.length == 1) {
        onSelectedCredential(credentials.first.id);
      } else {
        List<Widget> widgets = List.empty(growable: true);

        for (Credential credential in credentials) {
          widgets.add(SimpleDialogItem(
            key: Key(credential.id),
            text: credential.identity.displayName,
            onPressed: () {
              Navigator.pop(context, credential.id);
              onSelectedCredential(credential.id);
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
    onSelectCredential((credentialId) async {
      String authResultText = '';

      try {
        // Present the dialog to the user
        var result = await FlutterWebAuth.authenticate(
          url: "https://auth-us.beyondidentity.com/v1/tenants/00012da391ea206d/realms/862e4b72cfdce072/applications/3d869893-08b1-46ca-99c7-3c12226edf1b/authorize"
              "?scope=openid"
              "&response_type=code"
              "&redirect_uri=${Uri.encodeComponent("acme://")}"
              "&client_id=JvV5DbxFZbana_tMTAPTs-gY",
          callbackUrlScheme: "acme",
        );

        // Extract token from resulting url
        var authenticateResponse =
            await Embeddedsdk.authenticate(result, credentialId);
        authResultText = jsonPrettyPrint(authenticateResponse.toString());
      } on PlatformException catch (e) {
        errorPrint(e);
        authResultText = "could not authenticate $e";
      } catch (e) {
        errorPrint(e);
        authResultText = "${e.runtimeType} authenticating = $e";
      }

      if (!mounted) return;

      setState(() {
        _authBeyondIdentityResultText = authResultText;
      });
    });
  }

  Future<void> _authenticateOkta() async {
    onSelectCredential((credentialId) async {
      String authResultText = '';

      final pkcePair = PkcePair.generate();

      try {
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

        if (await Embeddedsdk.isAuthenticateUrl(oktaResult)) {
          // Extract token from resulting url
          var authenticateResponse =
              await Embeddedsdk.authenticate(oktaResult, credentialId);
          authResultText = jsonPrettyPrint(authenticateResponse.toString());

          // Present the dialog to the user
          oktaResult = await FlutterWebAuth.authenticate(
            url: authenticateResponse.redirectUrl,
            callbackUrlScheme: "acme",
          );
        }

        // Extract token from resulting url
        final code = Uri.parse(oktaResult).queryParameters['code'];

        http.Client client =
            InterceptedClient.build(interceptors: [LoggingInterceptor()]);

        try {
          var response = await client.post(
            Uri.parse("https://dev-43409302.okta.com/oauth2/v1/token"),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: {
              'client_id': '0oa5kipb8rdo4WCkf5d7',
              'code': code,
              'code_verifier': pkcePair.codeVerifier,
              'grant_type': 'authorization_code',
              'redirect_uri': 'acme://okta',
            },
          );

          authResultText = jsonPrettyPrint(response.body);
        } catch (e) {
          errorPrint(e);
          authResultText = "${e.runtimeType} authenticating = $e";
        } finally {
          client.close();
        }
      } on PlatformException catch (e) {
        errorPrint(e);
        authResultText = "could not authenticate $e";
      } catch (e) {
        errorPrint(e);
        authResultText = "${e.runtimeType} authenticating = $e";
      }

      if (!mounted) return;

      setState(() {
        _authOktaResultText = authResultText;
      });
    });
  }

  Future<void> _authenticateAuth0() async {
    onSelectCredential((credentialId) async {
      String authResultText = '';

      final pkcePair = PkcePair.generate();

      try {
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

        if (await Embeddedsdk.isAuthenticateUrl(auth0Result)) {
          // Extract token from resulting url
          var authenticateResponse =
              await Embeddedsdk.authenticate(auth0Result, credentialId);
          authResultText = authenticateResponse.toString();

          // Present the dialog to the user
          auth0Result = await FlutterWebAuth.authenticate(
            url: authenticateResponse.redirectUrl,
            callbackUrlScheme: "acme",
          );
        }

        // Extract token from resulting url
        final code = Uri.parse(auth0Result).queryParameters['code'];

        http.Client client =
            InterceptedClient.build(interceptors: [LoggingInterceptor()]);

        try {
          var response = await client.post(
            Uri.parse("https://dev-pt10fbkg.us.auth0.com/oauth/token"),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: {
              'grant_type': 'authorization_code',
              'client_id': 'q1cubQfeZWnajq5YkeZVD3NauRqU4vNs',
              'code': code,
              'code_verifier': pkcePair.codeVerifier,
              'redirect_uri': 'acme://auth0',
            },
          );

          authResultText = jsonPrettyPrint(response.body);
        } catch (e) {
          errorPrint(e);
          authResultText = "${e.runtimeType} authenticating = $e";
        } finally {
          client.close();
        }
      } on PlatformException catch (e) {
        errorPrint(e);
        authResultText = "could not authenticate $e";
      } catch (e) {
        errorPrint(e);
        authResultText = "${e.runtimeType} authenticating = $e";
      }

      if (!mounted) return;

      setState(() {
        _authAuth0ResultText = authResultText;
      });
    });
  }

  Future<void> _authenticate() async {
    onSelectCredential((credentialId) async {
      String authText = _authText;
      String authResultText = '';

      try {
        AuthenticateResponse authenticateResponse =
            await Embeddedsdk.authenticate(_authController.text, credentialId);
        authText = '';
        authResultText = jsonPrettyPrint(authenticateResponse.toString());
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
    });
  }

  Future<void> _getCredentials() async {
    String getCredentialsResultText = '';

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      List<Credential> credentials = await Embeddedsdk.getCredentials();
      getCredentialsResultText = "Credentials = $credentials";
    } on PlatformException catch (e) {
      errorPrint(e);
      getCredentialsResultText = "could not get credentials $e";
    } catch (e) {
      errorPrint(e);
      getCredentialsResultText = "${e.runtimeType} getting credentials = $e";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _getCredentialsResultText = getCredentialsResultText;
    });
  }

  Future<void> _deleteCredential() async {
    String deleteCredentialText = _deleteCredentialText;
    String deleteCredentialResultText = '';

    try {
      if (_deleteCredentialController.text.isNotEmpty) {
        await Embeddedsdk.deleteCredential(_deleteCredentialController.text);
        deleteCredentialText = '';
        deleteCredentialResultText = "Deleted credential ${_deleteCredentialController.text}";
      } else {
        List<Credential> credentials = await Embeddedsdk.getCredentials();
        if (credentials.isNotEmpty) {
          await Embeddedsdk.deleteCredential(credentials.first.id);
          deleteCredentialText = '';
          deleteCredentialResultText = "Deleted credential ${credentials.first.id}";
        } else {
          deleteCredentialText = '';
          deleteCredentialResultText = "No credentials to delete";
        }
      }
    } on PlatformException catch (e) {
      errorPrint(e);
      deleteCredentialResultText = "could not delete credential $e";
    } catch (e) {
      errorPrint(e);
      deleteCredentialResultText = "${e.runtimeType} deleting credential = $e";
    }

    if (!mounted) return;

    setState(() {
      _deleteCredentialText = deleteCredentialText;
      _deleteCredentialResultText = deleteCredentialResultText;
    });
  }

  Future<void> _bindUrl() async {
    String bindUrlText = _bindUrlText;
    String bindUrlResultText = '';

    try {
      bool isBindUrl =
          await Embeddedsdk.isBindCredentialUrl(_bindUrlController.text);
      bindUrlText = '';
      bindUrlResultText = isBindUrl.toString();
    } on PlatformException catch (e) {
      errorPrint(e);
      bindUrlResultText = "could not validate bind credential url $e";
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
          await Embeddedsdk.isAuthenticateUrl(_authUrlController.text);
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
    if (!await launchUrl(uri)) {
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

  void errorPrint(Object e) {
    debugPrint("${e.runtimeType} = $e");
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
                  _subTitle("Bind Credential"),
                  _description("To get started with using our embedded SDK sample app, enter any username to bind a credential to this device."),
                  _buttonInputTextGroup("Bind Credential", "Username", _registerUserController, _registerDemoUser, _registerUserText),
                  Text(_registerUserResultText),
                  _subTitle("Recover Credential"),
                  _description("If you have an account with a credential you can’t access anymore, enter your username to recover your account and bind a credential to this device."),
                  _buttonInputTextGroup("Recover Credential", "Username", _recoverUserController, _recoverDemoUser, _recoverUserText),
                  Text(_recoverUserResultText),
                ]),
                _card([
                  _title("\nBind Credential"),
                  _description("Paste the Bind Credential URL you received in your email or generated through the API in order to bind a credential."),
                  _buttonInputTextGroup("Bind Credential", "Bind Credential URL", _bindController, _bind, _bindText),
                  Text(_bindResultText),
                ]),
                _card([
                  _title("\nAuthenticate"),
                  _description("Authenticate against a credential bound to this device. If more than one credential is present, you must select a credential during authentication."),
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
                  _description("Authenticate against a credential bound to this device. If more than one credential is present, you must select a credential during authentication."),
                  _buttonInputTextGroup("Authenticate", "Authenticate URL", _authController, _authenticate, _authText),
                  Text(_authResultText),
                ]),
                _card([
                  _title("\nCredential Management"),
                  _subTitle("View Credential"),
                  _description("View details of your Credential, such as date created, identity and other information related to your device."),
                  _buttonTextGroup("Get Credentials", _getCredentials, _getCredentialsResultText),
                  _subTitle("Delete Credential"),
                  _description("Delete your credential on your device."),
                  _buttonInputTextGroup("Delete Credential", "Credential ID", _deleteCredentialController, _deleteCredential, _deleteCredentialText),
                  Text(_deleteCredentialResultText),
                ]),
                _card([
                  _title("\nURL Validation"),
                  _subTitle("Bind Credential URL"),
                  _description("Paste a Url here to validate if it's a bind credential url."),
                  _buttonInputTextGroup("Validate URL", "Bind Credential URL", _bindUrlController, _bindUrl, _bindUrlText),
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
