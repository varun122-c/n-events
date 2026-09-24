package com.nvents.n_vents

import android.content.Context
import android.os.Build
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nvents.app/sim"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceSimInfo") {
                try {
                    val simInfoList = ArrayList<Map<String, String>>()
                    val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                    val simOperatorName = telephonyManager.simOperatorName ?: ""
                    val networkOperatorName = telephonyManager.networkOperatorName ?: ""

                    var line1Number = ""
                    try {
                        line1Number = telephonyManager.line1Number ?: ""
                    } catch (e: Exception) {
                        line1Number = ""
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                        val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                        try {
                            val activeList = subscriptionManager.activeSubscriptionInfoList
                            if (activeList != null && activeList.isNotEmpty()) {
                                for (info in activeList) {
                                    val map = HashMap<String, String>()
                                    map["carrierName"] = info.carrierName?.toString() ?: simOperatorName
                                    map["displayName"] = info.displayName?.toString() ?: ""
                                    map["countryIso"] = info.countryIso ?: ""
                                    map["simSlotIndex"] = info.simSlotIndex.toString()

                                    var num = info.number ?: ""
                                    if (num.isEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                        try {
                                            num = subscriptionManager.getPhoneNumber(info.subscriptionId)
                                        } catch (e: Exception) {}
                                    }
                                    if (num.isEmpty()) {
                                        num = line1Number
                                    }
                                    map["phoneNumber"] = num
                                    simInfoList.add(map)
                                }
                            }
                        } catch (e: Exception) {
                            // Permission restricted
                        }
                    }

                    if (simInfoList.isEmpty()) {
                        val map = HashMap<String, String>()
                        map["carrierName"] = if (simOperatorName.isNotEmpty()) simOperatorName else networkOperatorName
                        map["displayName"] = if (networkOperatorName.isNotEmpty()) networkOperatorName else "Cellular Network"
                        map["countryIso"] = telephonyManager.simCountryIso ?: "in"
                        map["simSlotIndex"] = "0"
                        map["phoneNumber"] = line1Number
                        simInfoList.add(map)
                    }

                    result.success(simInfoList)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Failed to fetch hardware SIM info: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
