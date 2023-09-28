package com.beyondidentity.flutter.embeddedsdk

import android.app.Activity
import android.app.Application
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.beyondidentity.embedded.sdk.EmbeddedSdk
import com.beyondidentity.embedded.sdk.models.AuthenticateResponse
import com.beyondidentity.embedded.sdk.models.BindPasskeyResponse
import com.beyondidentity.embedded.sdk.models.AuthenticationContext
import com.beyondidentity.embedded.sdk.models.Passkey
import com.beyondidentity.embedded.sdk.models.OtpChallengeResponse
import com.beyondidentity.embedded.sdk.models.RedeemOtpResponse
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

/** EmbeddedSdkPlugin */
class EmbeddedSdkPlugin : ActivityAware, FlutterPlugin, MethodCallHandler,
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
                    val biometricAskPrompt: String? = call.argument("biometricAskPrompt")
                    call.argument<Boolean>("enableLogger")?.let {
                        if (it) {
                            this.logger = { log ->
                                Handler(Looper.getMainLooper()).post {
                                    val args: MutableMap<String, Any> = HashMap()
                                    args["message"] = log
                                    channel.invokeMethod("print", args)
                                }
                            }
                        }
                    }

                    checkNulls(app, biometricAskPrompt)?.let { (app, biometricAskPrompt) ->
                        EmbeddedSdk.init(
                            app = app as Application,
                            keyguardPrompt = keyguardPrompt,
                            logger = this.logger,
                            biometricAskPrompt = biometricAskPrompt as String,
                            allowedDomains = allowedDomains,
                        )
                        isEmbeddedSdkInitialized = true
                    } ?: result.error(EMBEDDED_SDK_ERROR, "Failed to initialize EmbeddedSdk", null)
                }
                "bindPasskey" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.bindPasskey(url) { bindPasskeyResult ->
                            bindPasskeyResult.onSuccess { bindPasskeyResponse ->
                                result.success(
                                    makeBindPasskeyMap(
                                        bindPasskeyResponse
                                    )
                                )
                            }
                            bindPasskeyResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get bindPasskey arguments",
                        null
                    )
                }
                "authenticate" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.authenticate(
                            url,
                            call.argument<String>("passkeyId") ?: "",
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
                "authenticateOtp" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.authenticateOtp(
                            url,
                            call.argument<String>("email") ?: "",
                        ) { authenticateResult ->
                            authenticateResult.onSuccess { otpChallengeResponse ->
                                result.success(
                                    makeOtpChallengeResponseMap(
                                        otpChallengeResponse
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
                        "Could not get authenticateOtp arguments",
                        null
                    )
                }
                "getAuthenticationContext" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.getAuthenticationContext(url) { authContextResult ->
                            authContextResult.onSuccess { authContextResponse ->
                                result.success(
                                    makeAuthenticationContextResponseMap(
                                        authContextResponse
                                    )
                                )
                            }
                            authContextResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get getAuthenticationContext arguments",
                        null
                    )
                }
                "getPasskeys" -> {
                    EmbeddedSdk.getPasskeys { getPasskeysResult ->
                        getPasskeysResult.onSuccess { passkeys ->
                            result.success(passkeys.map { passkey ->
                                makePasskeyMap(
                                    passkey
                                )
                            })
                        }
                        // TODO standardize error messaging between iOS and Android
                        getPasskeysResult.onFailure {
                            result.error(
                                EMBEDDED_SDK_ERROR,
                                it.localizedMessage,
                                null
                            )
                        }
                    }
                }
                "deletePasskey" -> {
                    call.argument<String>("passkeyId")?.let { passkeyId ->
                        EmbeddedSdk.deletePasskey(passkeyId) { deletePasskeyResult ->
                            deletePasskeyResult.onSuccess { result.success(passkeyId) }
                            deletePasskeyResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get deletePasskey arguments",
                        null
                    )
                }
                "isBindPasskeyUrl" -> {
                    call.argument<String>("url")?.let { url ->
                        result.success(EmbeddedSdk.isBindPasskeyUrl(url))
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get isBindPasskeyUrl arguments",
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
                "redeemOtp" -> {
                    call.argument<String>("url")?.let { url ->
                        EmbeddedSdk.redeemOtp(
                            url,
                            call.argument<String>("otp") ?: "",
                        ) { redeemResult ->
                            redeemResult.onSuccess { redeemOtpResponse ->
                                when (redeemOtpResponse) {
                                    is RedeemOtpResponse.Success -> {
                                        val authResponse = redeemOtpResponse.authenticateResponse
                                        result.success(
                                            makeAuthenticateMap(
                                                authResponse
                                            )
                                        )
                                    }
                                    is RedeemOtpResponse.FailedOtp -> {
                                        val otpChallengeResponse = redeemOtpResponse.otpChallengeResponse
                                        result.success(
                                            makeOtpChallengeResponseMap(
                                                otpChallengeResponse
                                            )
                                        )
                                    }
                                }
                            }
                            redeemResult.onFailure {
                                result.error(
                                    EMBEDDED_SDK_ERROR,
                                    it.localizedMessage,
                                    null
                                )
                            }
                        }
                    } ?: result.error(
                        EMBEDDED_SDK_ERROR,
                        "Could not get redeemOtp arguments",
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
        "passkeyBindingToken" to authenticateResponse.passkeyBindingToken,
    )

    private fun makeOtpChallengeResponseMap(otpChallengeResponseMap: OtpChallengeResponse)= mapOf(
        "url" to otpChallengeResponseMap.url,
    )

    private fun makeBindPasskeyMap(bindPasskeyResponse: BindPasskeyResponse) = mapOf(
        "passkey" to makePasskeyMap(bindPasskeyResponse.passkey),
        "postBindingRedirectUri" to bindPasskeyResponse.postBindingRedirectUri,
    )

    private fun makeAuthenticationContextResponseMap(authenticationContext: AuthenticationContext) = mapOf(
        "authUrl" to authenticationContext.authUrl,
        "application" to mapOf(
            "id" to authenticationContext.application.id,
            "displayName" to authenticationContext.application.displayName,
        ),
        "origin" to mapOf(
            "sourceIp" to authenticationContext.origin.sourceIp,
            "userAgent" to authenticationContext.origin.userAgent,
            "geolocation" to authenticationContext.origin.geolocation,
            "referer" to authenticationContext.origin.referer
        ),
    )

    private fun makePasskeyMap(passkey: Passkey) = mapOf(
        "id" to passkey.id,
        "localCreated" to passkey.localCreated.toString(),
        "localUpdated" to passkey.localUpdated.toString(),
        "apiBaseUrl" to passkey.apiBaseUrl.toString(),
        "keyHandle" to passkey.keyHandle,
        "state" to passkey.state.toString(),
        "created" to passkey.created.toString(),
        "updated" to passkey.updated.toString(),
        "tenant" to mapOf(
            "id" to passkey.tenant.id,
            "displayName" to passkey.tenant.displayName,
        ),
        "realm" to mapOf(
            "id" to passkey.realm.id,
            "displayName" to passkey.realm.displayName,
        ),
        "identity" to mapOf(
            "id" to passkey.identity.id,
            "displayName" to passkey.identity.displayName,
            "username" to passkey.identity.username,
            "primaryEmailAddress" to passkey.identity.primaryEmailAddress,
        ),
        "theme" to mapOf(
            "logoLightUrl" to passkey.theme.logoLightUrl.toString(),
            "logoDarkUrl" to passkey.theme.logoDarkUrl.toString(),
            "supportUrl" to passkey.theme.supportUrl.toString(),
        ),
    )

    companion object {
        const val EMBEDDED_KEYGUARD_REQUEST = 4936

        const val EMBEDDED_METHOD_CHANNEL = "embeddedsdk_method_channel"
        const val EMBEDDED_EVENT_CHANNEL = "embeddedsdk_event_channel"

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
