package com.beyondidentity.flutter.embeddedsdk

import android.app.Activity
import android.app.Application
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.beyondidentity.embedded.sdk.EmbeddedSdk
import com.beyondidentity.embedded.sdk.models.AuthenticateResponse
import com.beyondidentity.embedded.sdk.models.BindCredentialResponse
import com.beyondidentity.embedded.sdk.models.Credential
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
class EmbeddedsdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var isEmbeddedSdkInitialized = false

    private var keyguardPrompt: (((Boolean, Exception) -> Unit) -> Unit)? = null
    private var currentActivity: Activity? = null
    private var logger: (String) -> Unit = { }

    @Suppress("UNCHECKED_CAST")
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, EMBEDDED_METHOD_CHANNEL)
        channel.setMethodCallHandler(this)

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
                    val allowedDomains: List<String>? = call.argument("allowedDomains")
                    val biometricPrompt: String? = call.argument("biometricPrompt")
                    call.argument<Boolean>("enableLogging")?.let {
                        if (it) {
                            this.logger = { log -> Log.d("FlutterEmbedded", log) }
                        }
                    }

                    checkNulls(app, biometricPrompt)?.let { (app, biometricPrompt) ->
                        EmbeddedSdk.init(
                            app = app as Application,
                            keyguardPrompt = keyguardPrompt,
                            logger = this.logger,
                            biometricAskPrompt = biometricPrompt as String,
                            allowedDomains = allowedDomains,
                        )
                        isEmbeddedSdkInitialized = true
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Failed to initialize EmbeddedSdk", null)
                }
                "bindCredential" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.bindCredential(url) { bindCredentialResult ->
                            bindCredentialResult.onSuccess { bindCredentialResponse ->
                                result.success(
                                    makeBindCredentialMap(
                                        bindCredentialResponse
                                    )
                                )
                            }
                            bindCredentialResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get bindCredential arguments",
                        null
                    )
                }
                "authenticate" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.authenticate(
                            url,
                            call.argument<String>("credentialId") ?: "",
                        ) { authenticateResult ->
                            authenticateResult.onSuccess { authenticateResponse ->
                                result.success(
                                    makeAuthenticateMap(
                                        authenticateResponse
                                    )
                                )
                            }
                            authenticateResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get authenticate arguments",
                        null
                    )
                }
                "getCredentials" -> {
                    EmbeddedSdk.getCredentials { getCredentialsResult ->
                        getCredentialsResult.onSuccess { credentials ->
                            result.success(credentials.map { credential ->
                                makeCredentialMap(
                                    credential
                                )
                            })
                        }
                        // TODO standardize error messaging between iOS and Android
                        getCredentialsResult.onFailure {
                            result.error(
                                EMBEDDED_SDK_ERROR,
                                it.localizedMessage,
                                null
                            )
                        }
                    }
                }
                "deleteCredential" -> {
                    call.argument<String>("credentialId")?.let { id ->
                        EmbeddedSdk.deleteCredential(id) { deleteCredentialResult ->
                            deleteCredentialResult.onSuccess { result.success(id) }
                            deleteCredentialResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get deleteCredential arguments",
                        null
                    )
                }
                "isBindCredentialUrl" -> {
                    call.argument<String>("url")?.let { url ->
                        result.success(EmbeddedSdk.isBindCredentialUrl(url))
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get isBindCredentialUrl arguments",
                        null
                    )
                }
                "isAuthenticateUrl" -> {
                    call.argument<String>("url")?.let { url ->
                        result.success(EmbeddedSdk.isAuthenticateUrl(url))
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get isAuthenticateUrl arguments",
                        null
                    )
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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

    private fun makeAuthenticateMap(authenticateResponse: AuthenticateResponse) = mapOf(
        "redirectUrl" to authenticateResponse.redirectUrl,
        "message" to authenticateResponse.message,
    )

    private fun makeBindCredentialMap(bindCredentialResponse: BindCredentialResponse) = mapOf(
        "credential" to makeCredentialMap(bindCredentialResponse.credential),
        "postBindingRedirectUri" to bindCredentialResponse.postBindingRedirectUri,
    )

    private fun makeCredentialMap(credential: Credential) = mapOf(
        "id" to credential.id,
        "localCreated" to credential.localCreated.toString(),
        "localUpdated" to credential.localUpdated.toString(),
        "apiBaseUrl" to credential.apiBaseURL.toString(),
        "tenantId" to credential.tenantId,
        "realmId" to credential.realmId,
        "identityId" to credential.identityId,
        "keyHandle" to credential.keyHandle,
        "state" to credential.state.toString(),
        "created" to credential.created.toString(),
        "updated" to credential.updated.toString(),
        "tenant" to mapOf(
            "displayName" to credential.tenant.displayName,
        ),
        "realm" to mapOf(
            "displayName" to credential.realm.displayName,
        ),
        "identity" to mapOf(
            "displayName" to credential.identity.displayName,
            "username" to credential.identity.username,
            "primaryEmailAddress" to credential.identity.primaryEmailAddress,
        ),
        "theme" to mapOf(
            "logoLightUrl" to credential.theme.logoUrlLight.toString(),
            "logoDarkUrl" to credential.theme.logoUrlDark.toString(),
            "supportUrl" to credential.theme.supportUrl.toString(),
        )
    )

    companion object {
        const val EMBEDDED_KEYGUARD_REQUEST = 4936

        const val EMBEDDED_METHOD_CHANNEL = "embeddedsdk_method_channel"
        const val EMBEDDED_EXPORT_EVENT_CHANNEL = "embeddedsdk_export_event_channel"

        const val EMBEDDED_SDK_ERROR = "FlutterEmbeddedSdkError"
    }
}

fun <T : Any> checkNulls(vararg elements: T?): Array<T>? {
    if (null in elements) {
        return null
    }
    @Suppress("UNCHECKED_CAST")
    return elements as Array<T>
}
