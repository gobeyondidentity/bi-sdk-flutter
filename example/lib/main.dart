import 'dart:async';
import 'dart:convert';

import 'package:embeddedsdk/embeddedsdk.dart';
import 'package:embeddedsdk_example/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:uuid/uuid.dart';

bool _initialUriIsHandled = false;

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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bool _enableLogging = true;

  Domain _initDomain = Domain.us;
  String _initUSTenantText = '';
  String _initEUTenantText = '';

  final _createUserController = TextEditingController();
  String _createUserText = '';

  final _recoverUserController = TextEditingController();
  String _recoverUserText = '';

  Uri? _initialUri;
  Uri? _latestUri;
  Object? _err;
  StreamSubscription? _sub;

  Credential? _credentialRegistered;
  String _credentialRegisteredText = '';

  List<Credential>? _credentials;
  String _credentialsText = '';

  String _exportTokenText = '';

  String _importText = '';
  final _importTokenController = TextEditingController();

  String _deleteCredentialResult = '';

  String _authorizationCode = '';
  String _authorizationCodeText = '';
  String _authorizationExchangeTokenText = '';

  String _authTokenText = '';
  PKCE? _pkce;

  exportUpdateCallback(Map<String, String?> data) async {
    debugPrint("Export callback invoked $data");
    String? status = data["status"];
    String exportTokenText = "";
    if(status != null) {
      switch(status) {
        case ExtendCredentialsStatus.update: {
          if(data["token"] != null) {
            exportTokenText = "Extend token = ${data["token"]}";
          } else {
            exportTokenText = "error getting the token | data = $data";
          }
          break;
        }
        case ExtendCredentialsStatus.finish: {
          exportTokenText = "Credential extended successfully";
          break;
        }
        case ExtendCredentialsStatus.error: {
          exportTokenText = data["errorMessage"] ?? "error getting the errorMessage | data = $data";
          break;
        }
      }
    } else {
      exportTokenText = "extend credential status was null";
    }

    if (!mounted) return;

    setState(() {
      _exportTokenText = exportTokenText;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    Embeddedsdk.cancelExtendCredentials();
    _importTokenController.dispose();
    super.dispose();
  }

  void _initUSTenant() async {
    String initUSTenantText = '';

    setState(() {
      _initEUTenantText = initUSTenantText;
      _initUSTenantText = initUSTenantText;
    });

    initUSTenantText = _initTenant(Domain.us);

    setState(() {
      _initUSTenantText = initUSTenantText;
    });
  }

  void _initEUTenant() async {
    String initEUTenantText = '';

    setState(() {
      _initEUTenantText = initEUTenantText;
      _initUSTenantText = initEUTenantText;
    });

    initEUTenantText = _initTenant(Domain.eu);

    setState(() {
      _initEUTenantText = initEUTenantText;
    });
  }

  String _initTenant(Domain domain) {
    String initTenantText = '';

    try {
      _initDomain = domain;

      Embeddedsdk.initialize(BuildConfig.getPublicClientId(_initDomain), _initDomain, "Gimmie your biometrics", BuildConfig.REDIRECT_URI, _enableLogging);
      _handleInitialUri();
      _handleIncomingLinks();

      initTenantText = "Initialized Client on $_initDomain";
    } on Exception catch(e) {
      initTenantText = "Error initializing $e";
    }

    return initTenantText;
  }

  void _createDemoUser() async {
    String createUserText = '';
    http.Client client = InterceptedClient.build(interceptors: [
      LoggingInterceptor()
    ]);

    try {
      var uuid = const Uuid().v4().toString();
      var response = await client.post(
          Uri.parse(BuildConfig.getCreateUserUrl(_initDomain)),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${BuildConfig.getApiToken(_initDomain)}',
          },
          body: jsonEncode({
            'binding_token_delivery_method': 'email',
            'external_id': _createUserController.text,
            'email': _createUserController.text,
            'user_name': uuid,
            'display_name': uuid,
          }));

      createUserText = response.body;

    } on Exception catch(e) {
      createUserText = "Error creating user $e";
    } finally {
      client.close();
    }

    setState(() {
      _createUserText = createUserText;
    });
  }

  void _recoverDemoUser() async {
    String recoverUserText = '';
    http.Client client = InterceptedClient.build(interceptors: [
      LoggingInterceptor()
    ]);

    try {
      var response = await client.post(
          Uri.parse(BuildConfig.getRecoverUserUrl(_initDomain)),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer ${BuildConfig.getApiToken(_initDomain)}',
          },
          body: jsonEncode({
            'binding_token_delivery_method': 'email',
            'external_id': _recoverUserController.text,
          }));

      recoverUserText = response.body;

    } on Exception catch(e) {
      recoverUserText = "Error recovering user $e";
    } finally {
      client.close();
    }

    setState(() {
      _recoverUserText = recoverUserText;
    });
  }

  void _exchangeAuthzCodeForTokens() async {
    String responseText = '';
    if (_authorizationCode.isNotEmpty) {
      http.Client client = InterceptedClient.build(interceptors: [
        LoggingInterceptor()
      ]);

      Map<String, String> params = {
        'code': _authorizationCode,
        'redirect_uri': BuildConfig.REDIRECT_URI,
        'grant_type': 'authorization_code',
      };

      if(_pkce != null) {
        params['code_verifier'] = _pkce!.codeVerifier;
      }

      try {
        var response = await client.post(
            Uri.parse(BuildConfig.getTokenEndpoint(_initDomain)),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Basic ${base64Encode(utf8.encode('${BuildConfig.getConfidentialClientId(_initDomain)}:${BuildConfig.getConfidentialClientSecret(_initDomain)}'))}'
            },
            encoding: Encoding.getByName('utf-8'),
            body: params
        );

        responseText = response.body;

      } on Exception catch(e) {
        responseText = "Error exchanging authorization code for tokens $e";
      } finally {
        client.close();
      }
    } else {
      responseText = "Get Authorization Code first by clicking the Authorize button";
    }

    setState(() {
      _authorizationExchangeTokenText = responseText;
      _pkce = null;
    });
  }

  /// Handle incoming links - the ones that the app will receive from the OS
  /// while already started.
  void _handleIncomingLinks() {
    // It will handle app links while the app is already started - be it in
    // the foreground or in the background.
    _sub = uriLinkStream.listen((Uri? uri) {
      if (!mounted) return;
      debugPrint('got uri: $uri');
      _registerCredentialsWithUrl(uri);
      setState(() {
        _latestUri = uri;
        _err = null;
      });
    }, onError: (Object err) {
      if (!mounted) return;
      debugPrint('got err: $err');
      setState(() {
        _latestUri = null;
        if (err is FormatException) {
          _err = err;
        } else {
          _err = null;
        }
      });
    });
  }

  /// Handle the initial Uri - the one the app was started with
  ///
  /// **ATTENTION**: `getInitialLink`/`getInitialUri` should be handled
  /// ONLY ONCE in your app's lifetime, since it is not meant to change
  /// throughout your app's life.
  ///
  /// We handle all exceptions, since it is called from initState.
  Future<void> _handleInitialUri() async {
    // In this example app this is an almost useless guard, but it is here to
    // show we are not going to call getInitialUri multiple times, even if this
    // was a widget that will be disposed of (ex. a navigation route change).
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;

      try {
        final uri = await getInitialUri();
        if (uri == null) {
          debugPrint('no initial uri');
        } else {
          debugPrint('got initial uri: $uri');
        }
        _registerCredentialsWithUrl(uri);
        if (!mounted) return;
        setState(() {
          _initialUri = uri;
        });
      } on PlatformException {
        // Platform messages may fail but we ignore the exception
        debugPrint('failed to get initial uri');
      } on FormatException catch (err) {
        if (!mounted) return;
        debugPrint('malformed initial uri');
        setState(() => _err = err);
      }
    }
  }

  Future<void> _registerCredentialsWithUrl(Uri? registerUri) async {
    Credential? credential;
    String regCredText = '';
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    if (registerUri != null) {
      try {
        String uri = registerUri.toString().replaceAll(":?", "://host/register?");
        debugPrint("Register with = $uri");
        credential = await Embeddedsdk.registerCredentialsWithUrl(uri);
        regCredText = "Credential successfully registered";
      } on PlatformException catch (e) {
        debugPrint("platform exception = $e");
        regCredText = "Error registering credentials = $e";
      } on Exception catch (e) {
        debugPrint("exception = $e");
        regCredText = "Error registering credentials = $e";
      }
    }
    if (!mounted) return;

    setState(() {
      _credentialRegistered = credential;
      _credentialRegisteredText = regCredText;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _getCreds() async {
    List<Credential>? credentials;
    String credText = '';
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      credentials = await Embeddedsdk.getCredentials();
      credText = "Credentials = $credentials";
    } on PlatformException catch (e) {
      debugPrint("platform exception = $e");
      credText = "Error getting credentials = $e";
    } on Exception catch (e) {
      debugPrint("exception = $e");
      credText = "Error getting credentials = $e";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _credentials = credentials;
      _credentialsText = credText;
    });
  }

  Future<void> _createPkce() async {
    PKCE? pkce;

    try {
      pkce = await Embeddedsdk.createPkce();
    } on PlatformException {
      pkce = PKCE(codeVerifier: "error", codeChallenge: "error", codeChallengeMethod: "error");
    }

    if (!mounted) return;

    setState(() {
      _pkce = pkce;
    });
  }

  Future<void> _authorize() async {
    String authz;
    String authzText;

    Embeddedsdk.initialize(BuildConfig.getConfidentialClientId(_initDomain), _initDomain, "Gimmie your biometrics", BuildConfig.REDIRECT_URI, _enableLogging);

    try {
      authz = await Embeddedsdk.authorize(
          "openid",
          _pkce?.codeChallenge,
      );
      authzText = "Authorization code = $authz";
    } on PlatformException catch(e) {
      authz = '';
      authzText = "Error getting authz code | error = $e";
    }

    if (!mounted) return;

    setState(() {
      _authorizationCode = authz;
      _authorizationCodeText = authzText;
    });
  }

  Future<void> _extendCredentials() async {
    String exportToken;
    String exportTokenText;

    try {
      exportTokenText = "Export started";
      // test-acme-corp for devel, sdk-demo for prod
      Embeddedsdk.extendCredentials(List.generate(1, (index) => BuildConfig.DEMO_TENANT_HANDLE), exportUpdateCallback);
    } on PlatformException {
      exportTokenText = "Error exporting credential";
    }

    if (!mounted) return;

    setState(() {
      _exportTokenText = exportTokenText;
    });
  }

  Future<void> _cancelExtendCredentials() async {
    String cancelText = "";

    try {
      await Embeddedsdk.cancelExtendCredentials();
      cancelText = "Extend credentials cancelled";
    } on PlatformException {
      cancelText = "Error cancelling extend credentials";
    }

    if (!mounted) return;

    setState(() {
      _exportTokenText = cancelText;
    });
  }

  Future<void> _authenticate() async {
    TokenResponse token;
    String tokenText = "";

    Embeddedsdk.initialize(BuildConfig.getPublicClientId(_initDomain), _initDomain, "Gimmie your biometrics", BuildConfig.REDIRECT_URI, _enableLogging);

    try {
      token = await Embeddedsdk.authenticate();
      tokenText = token.toString();
    } on PlatformException {
      tokenText = 'Error getting auth token';
    }

    if (!mounted) return;

    setState(() {
      _authTokenText = tokenText;
    });
  }

  Future<void> _deleteCredential() async {
    String handle;

    try {
      handle = await Embeddedsdk.deleteCredential(BuildConfig.DEMO_TENANT_HANDLE);
    } on PlatformException catch(e) {
      handle = "could not delete credential $e";
    }

    if (!mounted) return;

    setState(() {
      _deleteCredentialResult = handle;
    });
  }

  Future<void> _registerCredentials() async {
    String importText = '';

    try {
      // test-acme-corp for devel, sdk-demo for prod
      await Embeddedsdk.registerCredentialsWithToken(_importTokenController.text);
      importText = "Credentials successfully registered";
    } on PlatformException catch(e) {
      importText = "Error registering credentials $e";
    }

    if (!mounted) return;

    setState(() {
      _importText = importText;
      _importTokenController.text = "";
    });
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
                _title("Tenant Utils"),
                _description("\nTenants:"),
                _buttonTextGroup("US Tenant", _initUSTenant, _initUSTenantText),
                _buttonTextGroup("EU Tenant", _initEUTenant, _initEUTenantText),
                _subTitle("\nNote: Before doing anything else, you must select a tenant"),
              ]),
              _card([
                _title("Demo Utils"),
                _description("\nCreate user for testing. Get an email with registration link."),
                _buttonInputTextGroup("Create Demo User", "User Email", _createUserController, _createDemoUser, _createUserText),
                _description("\nRecover existing user for testing. Get an email with recovery link."),
                _buttonInputTextGroup("Recover Demo User", "User Email", _recoverUserController, _recoverDemoUser, _recoverUserText),
              ]),
              _card([
                _title("\nEmbedded SDK Functionality"),
                _title("\nCredentials"),
                _subTitle("Credential is what identifies the user on this device."),
                Text(_credentialRegisteredText),
                _buttonTextGroup("Get Credentials", _getCreds, _credentialsText),
                _buttonTextGroup("Delete Credential", _deleteCredential, _deleteCredentialResult),
              ]),
              _card([
                _title("Extended/Register Credentials"),
                _subTitle("Before authenticating on another device, the credential needs to be transferred to that device."),
                _description("\nTransfer a credential from this to another device. Extend Credentials will generate an extended credential that can be used to register the credential on another device\nNOTE: Lock screen needs to be set on the device!"),
                _buttonTextGroup("Extend Credentials", _extendCredentials, _exportTokenText),
                _description("\nExtending Credentials blocks the Embedded SDK from performing other operations. The extended credential needs to finish or be explicitly cancelled."),
                _buttonTextGroup("Cancel Credentials Extend", _cancelExtendCredentials, ""),
                _description("To register credential from another device, enter the extended credential generated on that device."),
                _buttonInputTextGroup("Register Credentials", 'Extend credential from other device.', _importTokenController, _registerCredentials, _importText),
              ]),
              _card([
                _title("Access and ID token"),
                _subTitle("After successful authentication you will get an Access and ID token, used to get information on the user and authenticate on APIs. The flow of getting the tokens will depend on your OIDC client configuration."),
                _subTitle("There are 2 types of clients, Confidential (with client secret) and Public (without client secret).\n"),
                _title("OIDC Public client"),
                _subTitle("Public clients are unable to keep the secret secure (e.x. front end app with no backend)\n"),
                _description("Use authenticate function when your client is configured as public, it will go through the whole flow and get the Access and ID tokens"),
                _buttonTextGroup("Authenticate", _authenticate, _authTokenText),
                _title("\nOIDC Confidential client"),
                _subTitle("Confidential client are able to keep the secret secure (e.x. your backend)\n"),
                _description("(OPTIONAL) Use PKCE for increased security. If the flow is started with PKCE it needs to be completed with PKCE. Read more in the documentation."),
                _buttonTextGroup("Generate PKCE challenge", _createPkce, _pkce?.toString() ?? ""),
                _description("\nUse authorize function when your client is configured as confidential. You will get an authorization code that needs to be exchanged for Access and ID token."),
                _buttonTextGroup("Authorize", _authorize, _authorizationCodeText),
                _subTitle("\nExchange Authorization Code for Access and ID token."),
                _description("NOTE: To exchange the authorization code for Access and ID token we need the client secret."),
                _description("For demo purposes, we're storing the client secret on the device. DO NOT DO THIS IN PROD!"),
                _buttonTextGroup("Exchange Authz Code for Tokens", _exchangeAuthzCodeForTokens, _authorizationExchangeTokenText),
              ])
            ],
          ),
        ),
      )
    ));
  }

  Widget _card(List<Widget> widgets) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: widgets,
          ),
        )
    );
  }

  Widget _title(String titleText) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
            titleText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            )
        )
      ],
    );
  }

  Widget _subTitle(String subTitleText) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: Text(
              subTitleText,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              )
          ),
        )
      ],
    );
  }

  Widget _description(String description) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
              )
          ),
        )
      ],
    );
  }

  Widget _buttonTextGroup(String buttonLabel, VoidCallback callback, String text) {
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
}

