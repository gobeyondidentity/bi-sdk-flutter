import BeyondIdentityEmbedded
import Flutter
import UIKit
import os

let embeddedSdkMethodChannel = "embeddedsdk_method_channel"
let embeddedSdkEventChannel = "embeddedsdk_event_channel"

let embeddedSdkError = "FlutterEmbeddedSdkError"

public class SwiftEmbeddedSdkPlugin: NSObject, FlutterPlugin {

    var channel: FlutterMethodChannel? = nil
    var isEmbeddedSdkInitialized = false
    var logger: ((OSLogType, String) -> Void)? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftEmbeddedSdkPlugin()
        instance.channel = FlutterMethodChannel(name: embeddedSdkMethodChannel, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
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
               let allowedDomains = initArgs["allowedDomains"] as? [String],
               let biometricAskPrompt = initArgs["biometricAskPrompt"] as? String,
               let enableLogger = initArgs["enableLogger"] as? Bool {

                if (enableLogger) {
                    logger = { (_, message) in
                        DispatchQueue.main.async(execute: {
                            self.channel?.invokeMethod(
                                "print",
                                arguments: [
                                    "message": message,
                                ]
                            )
                        })
                    }
                }

                Embedded.initialize(allowedDomains: allowedDomains, biometricAskPrompt: biometricAskPrompt, logger: logger, callback: { _ in })

                isEmbeddedSdkInitialized = true
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get initialize arguments", details: nil))
            }

        case "bindPasskey":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get bindPasskey arguments", details: nil))
                return
            }

            if let bindArgs = args as? [String: Any?],
               let urlArg = bindArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                Embedded.shared.bindPasskey(url: url) { bindPasskeyResult in
                    switch bindPasskeyResult {
                    case let .success(bindPasskeyResponse):
                        result(makeBindPasskeyDictionary(bindPasskeyResponse))
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get bindPasskey arguments", details: nil))
            }

        case "authenticate":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get authenticate arguments", details: nil))
                return
            }

            if let authArgs = args as? [String: Any?],
               let urlArg = authArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                Embedded.shared.authenticate(url: url, id: Passkey.Id(authArgs["passkeyId"] as? String ?? "")) { authenticateResult in
                    switch authenticateResult {
                    case let .success(authenticateResponse):
                        result(makeAuthenticateDictionary(authenticateResponse))
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get authenticate arguments", details: nil))
            }

        case "getPasskeys":
            Embedded.shared.getPasskeys { getPasskeysResult in
                switch getPasskeysResult {
                case let .success(passkeys):
                    let passkeyDicts = passkeys.map(makePasskeyDictionary)
                    result(passkeyDicts)
                case .failure(let error):
                    // TODO: standardize error messaging between iOS and Android
                    result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                }
            }

        case "deletePasskey":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deletePasskey arguments", details: nil))
                return
            }

            if let deleteArgs = args as? [String: Any?],
               let passkeyId = deleteArgs["passkeyId"] as? String {
                Embedded.shared.deletePasskey(for: Passkey.Id(passkeyId)) { deletePasskeyResult in
                    switch deletePasskeyResult {
                    case .success:
                        result(passkeyId)
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deletePasskey arguments", details: nil))
            }

        case "isBindPasskeyUrl":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isBindPasskeyUrl arguments", details: nil))
                return
            }

            if let bindArgs = args as? [String: Any?],
               let urlArg = bindArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                result(Embedded.shared.isBindPasskeyUrl(url))
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isBindPasskeyUrl arguments", details: nil))
            }

        case "isAuthenticateUrl":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isAuthenticateUrl arguments", details: nil))
                return
            }

            if let bindArgs = args as? [String: Any?],
               let urlArg = bindArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                result(Embedded.shared.isAuthenticateUrl(url))
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isAuthenticateUrl arguments", details: nil))
            }

        default: result(FlutterError(code: embeddedSdkError, message: "\(call.method) not implemented for EmbeddedSDK", details: nil))
        }
    }
}

// MARK: HELPERS
private func makeAuthenticateDictionary(_ authenticateResponse: AuthenticateResponse) -> [String: Any?] {
    return [
        "redirectUrl" : authenticateResponse.redirectUrl.absoluteString,
        "message" : authenticateResponse.message,
    ]
}

private func makeBindPasskeyDictionary(_ bindPasskeyResponse: BindPasskeyResponse) -> [String: Any?] {
    return [
        "passkey" : makePasskeyDictionary(bindPasskeyResponse.passkey),
        "postBindingRedirectUri" : bindPasskeyResponse.postBindingRedirectUri?.absoluteString,
    ]
}

private func makePasskeyDictionary(_ passkey: Passkey) -> [String: Any?] {
    return [
        "id" : passkey.id.value,
        "localCreated" : passkey.localCreated.description,
        "localUpdated" : passkey.localUpdated.description,
        "apiBaseUrl" : passkey.apiBaseUrl.absoluteString,
        "keyHandle" : passkey.keyHandle.value,
        "state" : passkey.state.rawValue,
        "created" : passkey.created.description,
        "updated" : passkey.updated.description,
        "tenant": [
            "id": passkey.tenant.id.value,
            "displayName": passkey.tenant.displayName,
        ],
        "realm": [
            "id": passkey.realm.id.value,
            "displayName": passkey.realm.displayName,
        ],
        "identity": [
            "id": passkey.identity.id.value,
            "displayName": passkey.identity.displayName,
            "username": passkey.identity.username,
            "primaryEmailAddress": passkey.identity.primaryEmailAddress ?? "",
        ],
        "theme": [
            "logoLightUrl": passkey.theme.logoLightUrl.absoluteString,
            "logoDarkUrl": passkey.theme.logoDarkUrl.absoluteString,
            "supportUrl": passkey.theme.supportUrl.absoluteString,
        ],
    ]
}
