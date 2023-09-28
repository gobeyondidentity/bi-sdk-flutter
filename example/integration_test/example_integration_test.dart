import 'package:embeddedsdk_example/config.dart';
import 'package:embeddedsdk_example/extensions.dart';
import 'package:embeddedsdk_example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String keyDeletePasskey = "Delete Passkey";
  const String keyValidateBindPasskeyURL = "Validate Bind Passkey URL";
  const String keyValidateAuthenticateURL = "Validate Authenticate URL";

  // ignore: constant_identifier_names
  const String TEST_INVALID_USERNAME = "fake_id";
  // ignore: constant_identifier_names
  const String TEST_VALID_USERNAME = "jetpack_compose_test";
  // ignore: constant_identifier_names
  const String TEST_AUTHENTICATE_URL =
      "https://auth-us.beyondidentity.com/bi-authenticate?request=0123456789ABCDEF";
  // ignore: constant_identifier_names
  const String TEST_BIND_PASSKEY_URL =
      "https://auth-us.beyondidentity.com/v1/tenants/0123456789ABCDEF/realms/0123456789ABCDEF/identities/0123456789ABCDEF/credential-binding-jobs/0123456789ABCDEF:invokeAuthenticator?token=0123456789ABCDEF";

  /// Function to trigger a frame after `duration` amount of time.
  /// Note: [WidgetTester.pumpAndSettle] was working locally, but not in CI.
  ///
  /// [tester] [WidgetTester] object
  Future<void> testerPump(WidgetTester tester) async {
    // await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  group('embedded-sdk-functionality test group', () {
    testWidgets('embedded-sdk-functionality test widget', (tester) async {
      app.main();
      await testerPump(tester);

      expect(find.textContaining("Embedded SDK Functionality"), findsOneWidget);

      expect(find.text("SDK Version: ${BuildConfig.SDK_VERSION.capitalize()}"),
          findsOneWidget);

      expect(find.text("Environment: ${BuildConfig.ENVIRONMENT.capitalize()}"),
          findsOneWidget);
    });
  });

  /// Function to test and validate button, input and output
  ///
  /// [tester] [WidgetTester] object
  /// [keyValue] Key of the widget(s) to interact with
  /// [testerEnterText] Optional parameter to enter text into widget
  /// [findText] Optional parameter to find widget with text string
  /// [findTextContaining] Optional parameter to find widget with text containing string
  Future<void> validateInputAndOutput(WidgetTester tester, String keyValue,
      {String? testerEnterText,
      String? findText,
      String? findTextContaining}) async {
    app.main();
    await testerPump(tester);

    // Find widget by Key
    final findByKey = find.byKey(Key(keyValue));

    // Scroll until widget is visible
    await tester.dragUntilVisible(
        findByKey, find.byType(SingleChildScrollView), Offset.zero);

    // Optional: Enter text into input widget
    if (testerEnterText != null) {
      await tester.enterText(
          find.byKey(Key("$keyValue Input")), testerEnterText);
    }

    // Tap widget
    await tester.tap(findByKey);

    // Wait for idle frame
    await tester.pumpAndSettle();

    // Validate widget exists
    expect(findByKey, findsOneWidget);

    // Optional: Validate widget exists expected output
    if (findText != null) {
      expect(find.text(findText), findsOneWidget);
    }

    // Optional: Validate widget exists expected output
    if (findTextContaining != null) {
      expect(find.textContaining(findTextContaining), findsOneWidget);
    }
  }

  group('passkey-management test group', () {
    testWidgets('delete-passkey empty', (tester) async {
      await validateInputAndOutput(tester, keyDeletePasskey,
          findText: "Please enter a passkey id to delete");
    });

    testWidgets('delete-passkey invalid', (tester) async {
      await validateInputAndOutput(tester, keyDeletePasskey,
          testerEnterText: TEST_INVALID_USERNAME,
          findText: "Deleted passkey $TEST_INVALID_USERNAME");
    });

    testWidgets('delete-passkey valid', (tester) async {
      await validateInputAndOutput(tester, keyDeletePasskey,
          testerEnterText: TEST_VALID_USERNAME,
          findText: "Deleted passkey $TEST_VALID_USERNAME");
    });
  });

  group('url-validation test group', () {
    testWidgets('bind-passkey-url empty', (tester) async {
      await validateInputAndOutput(tester, keyValidateBindPasskeyURL,
          findText: "Please provide a Bind Passkey URL");
    });

    testWidgets('bind-passkey-url invalid', (tester) async {
      await validateInputAndOutput(tester, keyValidateBindPasskeyURL,
          testerEnterText: TEST_AUTHENTICATE_URL, findText: "false");
    });

    testWidgets('bind-passkey-url valid', (tester) async {
      await validateInputAndOutput(tester, keyValidateBindPasskeyURL,
          testerEnterText: TEST_BIND_PASSKEY_URL, findText: "true");
    });

    testWidgets('authenticate-url empty', (tester) async {
      await validateInputAndOutput(tester, keyValidateAuthenticateURL,
          findText: "Please provide an Authenticate URL");
    });

    testWidgets('authenticate-url invalid', (tester) async {
      await validateInputAndOutput(tester, keyValidateAuthenticateURL,
          testerEnterText: TEST_BIND_PASSKEY_URL, findText: "false");
    });

    testWidgets('authenticate-url valid', (tester) async {
      await validateInputAndOutput(tester, keyValidateAuthenticateURL,
          testerEnterText: TEST_AUTHENTICATE_URL, findText: "true");
    });
  });
}
