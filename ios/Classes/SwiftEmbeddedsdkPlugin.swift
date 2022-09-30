import BeyondIdentityEmbedded
import Flutter
import UIKit
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
               let allowedDomains = initArgs["allowedDomains"] as? [String],
               let biometricPrompt = initArgs["biometricPrompt"] as? String,
               let enableLogging = initArgs["enableLogging"] as? Bool {
                
                if (enableLogging) {
                    logger = { (_, message) in
                        print(message)
                    }
                }
                
                Embedded.initialize(allowedDomains: allowedDomains, biometricAskPrompt: biometricPrompt, logger: logger, callback: { _ in })
                
                isEmbeddedSdkInitialized = true
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get initialize arguments", details: nil))
            }

        case "bindCredential":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get bindCredential arguments", details: nil))
                return
            }

            if let bindArgs = args as? [String: Any?],
               let urlArg = bindArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                Embedded.shared.bindCredential(url: url) { bindCredentialResult in
                    switch bindCredentialResult {
                    case let .success(bindCredentialResponse):
                        result(makeBindCredentialDictionary(bindCredentialResponse))
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get bindCredential arguments", details: nil))
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
                Embedded.shared.authenticate(url: url, credentialID: CredentialID(authArgs["credentialId"] as? String ?? "")) { authenticateResult in
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

        case "getCredentials":
            Embedded.shared.getCredentials { credResult in
                switch credResult {
                case let .success(credentials):
                    let credentialDicts = credentials.map(makeCredentialDictionary)
                    result(credentialDicts)
                case .failure(let error):
                    // TODO: standardize error messaging between iOS and Android
                    result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                }
            }

        case "deleteCredential":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deleteCredential arguments", details: nil))
                return
            }
            
            if let deleteArgs = args as? [String: Any?],
               let credentialId = deleteArgs["credentialId"] as? String {
                Embedded.shared.deleteCredential(for: CredentialID(credentialId)) { deleteCredResult in
                    switch deleteCredResult {
                    case .success:
                        result(credentialId)
                    case let .failure(error):
                        result(FlutterError(code: embeddedSdkError, message: error.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get deleteCredential arguments", details: nil))
            }

        case "isBindCredentialUrl":
            guard let args = call.arguments else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isBindCredentialUrl arguments", details: nil))
                return
            }

            if let bindArgs = args as? [String: Any?],
               let urlArg = bindArgs["url"] as? String {
                guard let url = URL(string: urlArg) else {
                    result(FlutterError(code: embeddedSdkError, message: "\(urlArg) is not a valid url", details: nil))
                    return
                }
                result(Embedded.shared.isBindCredentialUrl(url))
            } else {
                result(FlutterError(code: embeddedSdkError, message: "Could not get isBindCredentialUrl arguments", details: nil))
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

class CredentialExportStreamHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

// MARK: HELPERS
private func makeAuthenticateDictionary(_ authenticateResponse: AuthenticateResponse) -> [String: Any?] {
    return [
        "redirectUrl" : authenticateResponse.redirectURL.absoluteString,
        "message" : authenticateResponse.message,
    ]
}

private func makeBindCredentialDictionary(_ bindCredentialResponse: BindCredentialResponse) -> [String: Any?] {
    return [
        "credential" : makeCredentialDictionary(bindCredentialResponse.credential),
        "postBindingRedirectUri" : bindCredentialResponse.postBindingRedirectURI?.absoluteString,
    ]
}

private func makeCredentialDictionary(_ credential: Credential) -> [String: Any?] {
    return [
        "id" : credential.id.value,
        "localCreated" : credential.localCreated.description,
        "localUpdated" : credential.localUpdated.description,
        "apiBaseUrl" : credential.apiBaseURL.absoluteString,
        "tenantId" : credential.tenantID.value,
        "realmId" : credential.realmID.value,
        "identityId" : credential.identityID.value,
        "keyHandle" : credential.keyHandle.value,
        "state" : credential.state.rawValue,
        "created" : credential.created.description,
        "updated" : credential.updated.description,
        "tenant": [
            "displayName": credential.tenant.displayName,
        ],
        "realm": [
            "displayName": credential.realm.displayName,
        ],
        "identity": [
            "displayName": credential.identity.displayName,
            "username": credential.identity.username,
            "primaryEmailAddress": credential.identity.primaryEmailAddress,
        ],
        "theme": [
            "logoLightUrl": credential.theme.logoLightURL.absoluteString,
            "logoDarkUrl": credential.theme.logoDarkURL.absoluteString,
            "supportUrl": credential.theme.supportURL.absoluteString,
        ]
    ]
}
