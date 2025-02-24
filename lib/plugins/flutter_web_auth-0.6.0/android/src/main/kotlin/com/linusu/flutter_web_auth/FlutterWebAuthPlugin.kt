package com.linusu.flutter_web_auth

import android.content.Context
import android.content.Intent
import android.net.Uri

import androidx.browser.customtabs.CustomTabsIntent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterWebAuthPlugin: FlutterPlugin, MethodCallHandler {

    companion object {
        val callbacks = mutableMapOf<String, Result>()
    }

    private var context: Context? = null
    private var channel: MethodChannel? = null

    // FlutterPlugin interface method - used to attach plugin to engine
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initInstance(binding.binaryMessenger, binding.applicationContext)
    }

    // FlutterPlugin interface method - used to detach plugin from engine
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        channel = null
    }

    // Initialize the plugin instance
    private fun initInstance(messenger: BinaryMessenger, context: Context) {
        this.context = context
        channel = MethodChannel(messenger, "flutter_web_auth")
        channel?.setMethodCallHandler(this)
    }

    // MethodCallHandler to handle method calls
    override fun onMethodCall(call: MethodCall, resultCallback: Result) {
        when (call.method) {
            "authenticate" -> {
                val url = Uri.parse(call.argument<String>("url"))
                val callbackUrlScheme = call.argument<String>("callbackUrlScheme")!!
                val preferEphemeral = call.argument<Boolean>("preferEphemeral")!!

                // Store the result callback associated with the callback URL scheme
                callbacks[callbackUrlScheme] = resultCallback

                val intent = CustomTabsIntent.Builder().build()
                val keepAliveIntent = Intent(context, KeepAliveService::class.java)

                intent.intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                if (preferEphemeral) {
                    intent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                }
                intent.intent.putExtra("android.support.customtabs.extra.KEEP_ALIVE", keepAliveIntent)

                intent.launchUrl(context!!, url)
            }
            "cleanUpDanglingCalls" -> {
                callbacks.forEach { (_, danglingResultCallback) ->
                    danglingResultCallback.error("CANCELED", "User canceled login", null)
                }
                callbacks.clear()
                resultCallback.success(null)
            }
            else -> resultCallback.notImplemented()
        }
    }
}
