import Flutter
import UIKit
import BeyondIdentityEmbedded
import os


let embeddedSdkError = "FlutterEmbeddedSdkError"

public class SwiftEmbeddedsdkPlugin: NSObject, FlutterPlugin {

    var isEmbeddedSdkInitialized = false
    var logger: ((OSLogType, String) -> Void)? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "embeddedsdk_method_channel", binaryMessenger: registrar.messenger())
        let exportEventChannel = FlutterEventChannel(name: "embeddedsdk_export_event_channel", binaryMessenger: registrar.messenger())
        let instance = SwiftEmbeddedsdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        exportEventChannel.setStreamHandler(CredentialExportStreamHandler())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (!isEmbeddedSdkInitialized && call.method != "initialize") {
            result(FlutterError(code: embeddedSdkError, message: "EmbeddedSdk not initialized", details: nil))
        }

        switch call.method {
        case "initialize":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get initialize arguments", details: nil))
                return
            }

            if let initArgs = args as? [String: Any],
               let clientId = initArgs["clientId"] as? String,
               let biometricPrompt = initArgs["biometricPrompt"] as? String, 
               let redirectUri = initArgs["redirectUri"] as? String,
               let enableLogging = initArgs["enableLogging"] as? Bool {

                if (enableLogging) {
                    logger = { (_, message) in
                        print(message)
                    }
                }

                Embedded.initialize(biometricAskPrompt: biometricPrompt, clientID: clientId, redirectURI: redirectUri, logger: logger)
                isEmbeddedSdkInitialized = true
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get initialize arguments", details: nil))
            }

        case "createPkce":
            Embedded.shared.createPKCE { pkceResult in
                switch pkceResult {
                case let .success(pkce):
                    let pkceResponse = [
                        "codeVerifier": pkce.codeVerifier,
                        "codeChallenge": pkce.codeChallenge.challenge,
                        "codeChallengeMethod": pkce.codeChallenge.method
                    ]
                    result(pkceResponse)
                case .failure(let error):
                    // TODO: standardize error messaging between iOS and Android
                    result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                }
            }

        case "getCredentials":
            Embedded.shared.getCredentials { credResult in
                switch credResult {
                case let .success(credentials):
                    let credentialDicts = credentials.map(self.makeCredentialDictionary)
                    result(credentialDicts)
                case .failure(let error):
                    // TODO: standardize error messaging between iOS and Android
                    result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                }
            }

        case "registerCredentialsWithUrl":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get registration arguments", details: nil))
                return
            }

            if let registrionArgs = args as? [String: Any],
               let stringUrl = registrionArgs["registerUri"] as? String,
               let url = URL(string: stringUrl) {
                Embedded.shared.registerCredentials(url, callback: { regRes in
                    switch regRes {
                    case let .success(cred):
                        result(self.makeCredentialDictionary(cred))
                    case let .failure(err):
                        result(FlutterError(code: embeddedSdkError, message: "Error registering Credential", details: err.localizedDescription))
                    }
                })
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get registration arguments", details: nil))
            }

        case "registerCredentialsWithToken":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get register arguments", details: nil))
                return
            }

            if let tokenArgs = args as? [String: Any?],
               let token = tokenArgs["token"] as? String {
                Embedded.shared.registerCredentials(token: CredentialToken(value: token)) { importResult in
                    switch importResult {
                    case let .success(credentials):
                        result(credentials.map(self.makeCredentialDictionary))
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get register arguments", details: nil))
            }

        case "deleteCredential":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deleteCredential arguments", details: nil))
                return
            }

            if let deleteArgs = args as? [String: Any?],
               let handle = deleteArgs["handle"] as? String {
                Embedded.shared.deleteCredential(for: Credential.Handle(handle)) { deleteCredResult in
                    switch deleteCredResult {
                    case let .success(handle):
                        result("Credential for \(handle) successfully deleted")
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deleteCredential arguments", details: nil))
            }

        case "cancelExtendCredentials":
            Embedded.shared.cancelExtendCredentials { cancelResult in
                switch cancelResult {
                case .success:
                    result("success")
                case .failure(let error):
                    result(FlutterError(code: embeddedSdkError, message: "Error canceling extend credentials \(error.localizedDescription)", details: nil))
                }
            }

        case "authorize":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get authorize arguments", details: nil))
                return
            }

            if let authArgs = args as? [String: Any],
               let scope = authArgs["scope"] as? String {

                var pkce: PKCE.CodeChallenge? = nil
                let pkceChallengeArg: String? = authArgs["pkceS256CodeChallenge"] as? String
                if (pkceChallengeArg != nil) {
                    pkce = PKCE.CodeChallenge(challenge: pkceChallengeArg!, method: "S256")
                }

                Embedded.shared.authorize(pkceChallenge: pkce, scope: scope) { authResult in
                    switch authResult {
                    case let .success(auth):
                        result(auth.value)
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get authorize arguments", details: nil))
            }

        case "authenticate":
            Embedded.shared.authenticate { authenticateResult in
                switch authenticateResult {
                case .success(let tokenResponse):
                    result([
                        "accessToken": tokenResponse.accessToken.value,
                        "idToken": tokenResponse.idToken,
                        "tokenType": tokenResponse.accessToken.type,
                        "expiresIn": tokenResponse.accessToken.expiresIn,
                    ])
                case .failure(let error):
                    result(FlutterError(code: embeddedSdkError, message: "Error authenticate \(error.localizedDescription)", details: nil))
                }
            }

        default: result(FlutterError(code: embeddedSdkError, message: "\(call.method) not implmented for EmbeddedSDK", details: nil))
        }
    }

    // MARK: HELPERS
    private func makeCredentialDictionary(_ credential: Credential) -> [String: Any?] {
        return [
            "created": credential.created,
            "handle": credential.handle?.value,
            "keyHandle": credential.keyHandle,
            "name": credential.name,
            "logoURL": credential.logoURL,
            "loginURI": credential.loginURI,
            "enrollURI": credential.enrollURI,
            "chain": credential.chain,
            "rootFingerprint": credential.rootFingerprint,
            "state": credential.state.rawValue
        ]
    }
}

class CredentialExportStreamHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let args = arguments else {
            events(FlutterError(code: embeddedSdkError, message: "Failed to get arguments for extendCredentials", details: nil))
            return nil
        }
        
        if let handleList = args as? [String] {
            Embedded.shared.extendCredentials(handles: handleList.map(Credential.Handle.init)) { result in
                switch result {
                case let .success(extendCredentialsStatus):
                    switch extendCredentialsStatus {
                    case .aborted:
                        events([ExtendCredentialsStatus.status.rawValue: ExtendCredentialsStatus.error.rawValue, "errorMessage": "aborted"])
                    case let .started(token, _), let .tokenUpdated(token, _):
                        events([ExtendCredentialsStatus.status.rawValue: ExtendCredentialsStatus.update.rawValue, "token": token.value])
                    case .done:
                        events([ExtendCredentialsStatus.status.rawValue: ExtendCredentialsStatus.finish.rawValue])
                    }
                case let .failure(error):
                    events(FlutterError(code: embeddedSdkError, message: "Error extending credential \(error.localizedDescription)", details: nil))
                }
            }
        } else {
            events(FlutterError(code: embeddedSdkError, message: "Failed to get arguments for extendCredentials", details: nil))
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Embedded.shared.cancelExtendCredentials { _ in }
        return nil
    }
}

enum ExtendCredentialsStatus: String, CaseIterable {
    case status
    case update
    case finish
    case error
}
