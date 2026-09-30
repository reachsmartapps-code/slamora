package com.smartappsin.slamora

import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val inviteChannelName = "slamora/invite_referrer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            inviteChannelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInstallReferrer") {
                readInstallReferrer(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun readInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()
        var didReply = false

        fun reply(value: String?) {
            if (didReply) {
                return
            }
            didReply = true
            result.success(value)
        }

        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                if (responseCode != InstallReferrerClient.InstallReferrerResponse.OK) {
                    client.endConnection()
                    reply(null)
                    return
                }

                try {
                    val response: ReferrerDetails = client.installReferrer
                    reply(response.installReferrer)
                } catch (_: Exception) {
                    reply(null)
                } finally {
                    client.endConnection()
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                reply(null)
            }
        })
    }
}
