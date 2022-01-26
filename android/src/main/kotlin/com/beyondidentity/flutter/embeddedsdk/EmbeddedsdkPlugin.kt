package com.beyondidentity.flutter.embeddedsdk

import android.app.Activity
import android.app.Application
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.beyondidentity.embedded.sdk.EmbeddedSdk
import com.beyondidentity.embedded.sdk.export.ExportCredentialListener
import com.beyondidentity.embedded.sdk.models.Credential
import com.beyondidentity.embedded.sdk.models.ExportResponse

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** EmbeddedsdkPlugin */
class EmbeddedsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var isEmbeddedSdkInitialized = false

    private var clientId: String? = null
    private var redirectUri: String? = null

    private var keyguardPrompt: (((Boolean, Exception) -> Unit) -> Unit)? = null
    private var currentActivity: Activity? = null
    private var logger: (String) -> Unit = { }

    @Suppress("UNCHECKED_CAST")
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, EMBEDDED_METHOD_CHANNEL)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EMBEDDED_EXPORT_EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                arguments?.let { args ->
                    (args as? List<String>)?.let { handleList ->
                        EmbeddedSdk.extendCredentials(
                            credentialHandles = handleList,
                            listener = object : ExportCredentialListener {
                                override fun onError(throwable: Throwable) {
                                    val updateMap = mapOf(
                                        ExtendCredentialsStatus.STATUS to ExtendCredentialsStatus.ERROR,
                                        "errorMessage" to throwable.localizedMessage
                                    )
                                    events?.success(updateMap)
                                }

                                override fun onFinish() {
                                    val updateMap = mapOf(ExtendCredentialsStatus.STATUS to ExtendCredentialsStatus.FINISH)
                                    events?.success(updateMap)
                                }

                                override fun onUpdate(token: ExportResponse?) {
                                    val updateMap = mapOf(
                                        ExtendCredentialsStatus.STATUS to ExtendCredentialsStatus.UPDATE,
                                        "token" to token?.rendezvousToken
                                    )
                                    events?.success(updateMap)
                                }

                            }
                        )
                    } ?: events?.error(EMBEDDED_SDK_ERROR, "No args passed for credential extend", null)
                } ?: events?.error(EMBEDDED_SDK_ERROR, "No args passed for credential extend", null)
            }

            override fun onCancel(arguments: Any?) {
                EmbeddedSdk.cancelExtendCredentials { }
            }

        })

        keyguardPrompt = { answer ->
            (flutterPluginBinding.applicationContext.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)
                ?.createConfirmDeviceCredentialIntent("Check", "Enter your pin or password")
                ?.let { intent ->
                    currentActivity?.startActivityForResult(intent, EMBEDDED_KEYGUARD_REQUEST)
                } ?: answer(false, IllegalStateException("Can not authenticate with KeyGuard!"))
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (!isEmbeddedSdkInitialized && call.method != "initialize") {
            result.error(EMBEDDED_SDK_ERROR, "EmbeddedSdk not initialized", null)
        } else {
            when (call.method) {
                "initialize" -> {
                    val app: Application? = currentActivity?.application
                    val clientId: String? = call.argument("clientId")
                    val biometricPrompt: String? = call.argument("biometricPrompt")
                    val redirectUri: String? = call.argument("redirectUri")
                    call.argument<Boolean>("enableLogging")?.let {
                        if(it) {
                            this.logger = { log -> Log.d("FlutterEmbedded", log) }
                        }
                    }

                    this.clientId = clientId
                    this.redirectUri = redirectUri
                    checkNulls(app, this.clientId, biometricPrompt)?.let { (app, clientId, biometricPrompt) ->
                        EmbeddedSdk.init(
                            app = app as Application,
                            keyguardPrompt = keyguardPrompt,
                            logger = this.logger,
                            clientId = clientId as String,
                            biometricAskPrompt = biometricPrompt as String,
                        )
                        isEmbeddedSdkInitialized = true
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Failed to initialize EmbeddedSdk", null)
                }
                "createPkce" -> {
                    EmbeddedSdk.createPkce { resultPkce ->
                        resultPkce.onSuccess { pkce ->
                            result.success(
                                mapOf(
                                    "codeVerifier" to pkce.codeVerifier,
                                    "codeChallenge" to pkce.codeChallenge,
                                    "codeChallengeMethod" to pkce.codeChallengeMethod
                                )
                            )
                        }
                        resultPkce.onFailure { t ->
                            result.error(
                                EMBEDDED_SDK_ERROR,
                                t.localizedMessage,
                                null
                            )
                        }
                    }
                }
                "registerCredentialsWithUrl" -> {
                    call.argument<String>("registerUri")?.let { uri ->
                        EmbeddedSdk.registerCredentialsWithUrl(uri) { credResult ->
                            credResult.onSuccess { cred -> result.success(makeCredentialMap(cred)) }
                            credResult.onFailure { result.error(EMBEDDED_SDK_ERROR, it.localizedMessage, null) }
                        }
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Could not get registerCredentialsWithUrl arguments", null)
                }
                "getCredentials" -> {
                    EmbeddedSdk.getCredentials { credResult ->
                        credResult.onSuccess { credList -> result.success(credList.map { cred -> makeCredentialMap(cred) }) }
                        // TODO standardize error messaging between iOS and Android
                        credResult.onFailure { result.error(EMBEDDED_SDK_ERROR, it.localizedMessage, null) }
                    }
                }

                "deleteCredential" -> {
                    call.argument<String>("handle")?.let { handle ->
                        EmbeddedSdk.deleteCredential(handle) { deleteCredResult ->
                            deleteCredResult.onSuccess { result.success(handle) }
                            deleteCredResult.onFailure { result.error(EMBEDDED_SDK_ERROR, it.localizedMessage, null) }
                        }
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Could not get deleteCredential arguments", null)
                }

                "authorize" -> {
                    val scope = call.argument<String>("scope")
                    val pkceS256CodeChallenge = call.argument<String>("pkceS256CodeChallenge")

                    checkNulls(this.clientId, this.redirectUri, scope)?.let { (clientId, redirectUri, scope) ->
                        EmbeddedSdk.authorize(
                            clientId = clientId,
                            redirectUri = redirectUri,
                            pkceS256CodeChallenge = pkceS256CodeChallenge,
                            scope = scope,
                        ) { credResult ->
                            credResult.onSuccess { result.success(it) }
                            credResult.onFailure { t ->
                                result.error(
                                    "EmbeddedError",
                                    t.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Could not get authorize arguments", null)
                }
                "authenticate" -> {
                    checkNulls(this.clientId, this.redirectUri)?.let { (cid, rUri) ->
                        EmbeddedSdk.authenticate(
                            clientId = cid,
                            redirectUri = rUri,
                        ) { credResult ->
                            credResult.onSuccess {
                                result.success(
                                    mapOf(
                                        "accessToken" to it.accessToken,
                                        "idToken" to it.idToken,
                                        "tokenType" to it.tokenType,
                                        "expiresIn" to it.expiresIn,
                                    )
                                )
                            }
                            credResult.onFailure { t -> result.error(EMBEDDED_SDK_ERROR, t.localizedMessage, null) }
                        }
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Could not get authenticate arguments", null)
                }
                "registerCredentialsWithToken" -> {
                    call.argument<String>("token")?.let { token ->
                        EmbeddedSdk.registerCredentialsWithToken(
                            token = token,
                        ) { credResult ->
                            credResult.onSuccess { result.success(it.map { cred -> makeCredentialMap(cred) }) }
                            credResult.onFailure { result.error(EMBEDDED_SDK_ERROR, it.localizedMessage, null) }
                        }
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Could not get registerCredentials arguments", null)
                }
                "cancelExtendCredentials" -> {
                    EmbeddedSdk.cancelExtendCredentials {
                        it.onSuccess { result.success("Extend credentials cancelled") }
                        it.onFailure { result.error(EMBEDDED_SDK_ERROR, "Error cancelling extend credentials", null) }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.removeActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == EMBEDDED_KEYGUARD_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                EmbeddedSdk.answer(true)
            } else {
                EmbeddedSdk.answer(false)
            }
        }

        return true
    }

    private fun makeCredentialMap(credential: Credential) = mapOf(
        "created" to credential.created,
        "handle" to credential.handle,
        "keyHandle" to credential.keyHandle,
        "name" to credential.name,
        "logoURL" to credential.imageUrl,
        "loginURI" to credential.loginUri,
        "enrollURI" to credential.enrollUri,
        "rootFingerprint" to credential.rootFingerprint,
        "chain" to credential.chain,
    )

    companion object {
        const val EMBEDDED_KEYGUARD_REQUEST = 4936

        const val EMBEDDED_METHOD_CHANNEL = "embeddedsdk_method_channel"
        const val EMBEDDED_EXPORT_EVENT_CHANNEL = "embeddedsdk_export_event_channel"

        const val EMBEDDED_SDK_ERROR = "FlutterEmbeddedSdkError"
    }
}

private object ExtendCredentialsStatus {
    const val STATUS = "status"
    const val UPDATE = "update"
    const val FINISH = "finish"
    const val ERROR = "error"
}

fun <T : Any> checkNulls(vararg elements: T?): Array<T>? {
    if (null in elements) {
        return null
    }
    @Suppress("UNCHECKED_CAST")
    return elements as Array<T>
}
