package com.huawo.sdkdemo

import android.app.Application
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.huawo.sdk.bluetoothsdk.BluetoothSDK
import com.huawo.sdk.bluetoothsdk.callback.ConnectCallback
import com.huawo.sdk.bluetoothsdk.callback.DisconnectCallback
import com.huawo.sdk.bluetoothsdk.core.callback.ScanCallback
import com.huawo.sdk.bluetoothsdk.core.model.Device
import com.huawo.sdk.bluetoothsdk.interfaces.callback.ActivityNumCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.BoolCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.BoolValueCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.ConnectionStateCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.CreateBondCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.DeviceInfoCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.HeartratesCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.HrvsCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.IntValueCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.RemoveBondCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.SleepsCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.Spo2Callback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.SportsCallback
import com.huawo.sdk.bluetoothsdk.interfaces.callback.StressCallback
import com.huawo.sdk.bluetoothsdk.interfaces.ops.GetActivityNum
import com.huawo.sdk.bluetoothsdk.interfaces.ops.GetSports
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.ActivityNum
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.DeviceInfo
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Gender
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Heartrate
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Hrv
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Sleep
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Spo2
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Sport
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Stress
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.Unit
import com.huawo.sdk.bluetoothsdk.interfaces.ops.models.UserInfo
import com.huawo.sdk.bluetoothsdk.interfaces.utils.LanguageUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Date

class HwBleBridge private constructor(
    private val application: Application,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var initialized = false
    private var connectionListenerRegistered = false
    private var scanSink: EventChannel.EventSink? = null
    private var connectionSink: EventChannel.EventSink? = null

    private val methodChannel =
        MethodChannel(messenger, METHOD_CHANNEL).also { it.setMethodCallHandler(::onMethodCall) }

    private val scanChannel =
        EventChannel(messenger, SCAN_CHANNEL).also { it.setStreamHandler(ScanStreamHandler()) }

    private val connectionChannel =
        EventChannel(messenger, CONNECTION_CHANNEL)
            .also { it.setStreamHandler(ConnectionStreamHandler()) }

    private val connectionStateCallback =
        object : ConnectionStateCallback() {
            override fun onConnectionStateChange(connected: Boolean) {
                emitConnectionEvent(connected)
            }
        }

    companion object {
        private const val TAG = "HwBleBridge"
        private const val METHOD_CHANNEL = "sdkdemo/hw_ble"
        private const val SCAN_CHANNEL = "sdkdemo/hw_ble/scan"
        private const val CONNECTION_CHANNEL = "sdkdemo/hw_ble/connection"

        fun register(activity: FlutterActivity, flutterEngine: FlutterEngine) {
            HwBleBridge(
                activity.applicationContext as Application,
                flutterEngine.dartExecutor.binaryMessenger,
            )
        }
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "destroy" -> handleDestroy(result)
            "getVersion" -> result.success(BluetoothSDK.getVersion())
            "stopScan" -> {
                BluetoothSDK.stopScan()
                result.success(null)
            }
            "connect" -> handleConnect(call, result)
            "disconnect" -> handleDisconnect(result)
            "isConnected" -> result.success(BluetoothSDK.isConnected())
            "startBind" -> BluetoothSDK.startBind(boolCallback(result, "startBind failed"))
            "startSifliBind" ->
                BluetoothSDK.startSifliBind(boolCallback(result, "startSifliBind failed"))
            "startQRCodeBind" ->
                BluetoothSDK.startQRCodeBind(boolCallback(result, "startQRCodeBind failed"))
            "endBind" -> BluetoothSDK.endBind(boolCallback(result, "endBind failed"))
            "setBind" -> {
                BluetoothSDK.setBind(call.argument<Boolean>("bind") == true)
                result.success(null)
            }
            "isBind" -> result.success(BluetoothSDK.isBind())
            "isBonded" -> result.success(BluetoothSDK.isBonded())
            "createBond" -> handleCreateBond(result)
            "removeBond" -> handleRemoveBond(result)
            "getPairState" -> result.success(BluetoothSDK.isBonded())
            "requestDeviceToPair" -> handleCreateBond(result)
            "getBtConnectionState" -> handleGetBtConnectionState(result)
            "setBtSwitchWithAutoConnect" -> handleSetBtSwitchWithAutoConnect(call, result)
            "unbindDevice" ->
                BluetoothSDK.clearDeviceData(boolCallback(result, "unbindDevice failed"))
            "removeConnectionCache" -> result.success(null)
            "setDeviceTime" -> handleSetDeviceTime(call, result)
            "setUserInfo" -> handleSetUserInfo(call, result)
            "setUnit" -> handleSetUnit(call, result)
            "setLanguage" -> handleSetLanguage(call, result)
            "getDeviceInfo" -> handleGetDeviceInfo(result)
            "getBindState" -> handleGetBindState(result)
            "getHealthDataCount" -> handleGetHealthDataCount(result)
            "getActivities" -> handleGetActivities(call, result)
            "deleteSports" -> BluetoothSDK.delSports(boolCallback(result, "deleteSports failed"))
            "getHeartrates" -> handleGetHeartrates(result)
            "deleteHeartrates" ->
                BluetoothSDK.delHeartrates(boolCallback(result, "deleteHeartrates failed"))
            "getSleeps" -> handleGetSleeps(result)
            "deleteSleeps" -> BluetoothSDK.delSleeps(boolCallback(result, "deleteSleeps failed"))
            "getActivitiesV2" -> handleGetActivitiesV2(result)
            "getSleepsV2" -> handleGetSleepsV2(result)
            "getHeartratesV2" -> handleGetHeartratesV2(result)
            "getSpo2sV2" -> handleGetSpo2sV2(result)
            "getStressesV2" -> handleGetStressesV2(result)
            "getHrvsV2" -> handleGetHrvsV2(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInit(call: MethodCall, result: MethodChannel.Result) {
        val maxMtu = toInt(call.argument<Any>("maxMtu"), 247)
        if (!initialized) {
            BluetoothSDK.init(application, maxMtu)
            initialized = true
            registerConnectionListener()
        }
        result.success(null)
    }

    private fun handleDestroy(result: MethodChannel.Result) {
        unregisterConnectionListener()
        if (initialized) {
            BluetoothSDK.destroy()
            initialized = false
        }
        result.success(null)
    }

    private fun handleConnect(call: MethodCall, result: MethodChannel.Result) {
        val mac = call.argument<String>("macAddress")
        if (mac.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "macAddress is required on Android", null)
            return
        }
        val timeoutMs = toInt(call.argument<Any>("timeoutSeconds"), 30) * 1000L
        BluetoothSDK.connect(
            mac,
            timeoutMs,
            object : ConnectCallback() {
                override fun onSuccess(device: Device) {
                    mainHandler.post {
                        emitConnectionEvent(true)
                        result.success(deviceMap(device))
                    }
                }

                override fun onFail(code: Int) {
                    mainHandler.post {
                        result.error(code.toString(), "connect failed", null)
                    }
                }
            },
        )
    }

    private fun handleDisconnect(result: MethodChannel.Result) {
        BluetoothSDK.disconnect(
            object : DisconnectCallback() {
                override fun onSuccess() {
                    mainHandler.post {
                        emitConnectionEvent(false)
                        result.success(null)
                    }
                }
            },
        )
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any? = null) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, code: Int, msg: String) {
        mainHandler.post { result.error(code.toString(), msg, null) }
    }

    private fun logWlEnter(method: String) {
        Log.i(TAG, "[WL_SYNC][ENTER] method=$method connected=${BluetoothSDK.isConnected()}")
    }

    private fun logWlSuccess(method: String, count: Int) {
        Log.i(TAG, "[WL_SYNC][RESULT] method=$method success=true count=$count")
    }

    private fun postWlError(result: MethodChannel.Result, method: String, code: Int) {
        Log.e(TAG, "[WL_SYNC][RESULT] method=$method success=false code=$code")
        postError(result, code, "$method failed")
    }

    private fun postWlMappingError(
        result: MethodChannel.Result,
        method: String,
        error: Exception,
    ) {
        Log.e(TAG, "[WL_SYNC][EXCEPTION] method=$method code=WL_MAP_ERROR", error)
        mainHandler.post {
            result.error("WL_MAP_ERROR", "$method mapping failed", error.message)
        }
    }

    private fun voidCallback(result: MethodChannel.Result, msg: String) =
        object : CreateBondCallback() {
            override fun onSuccess() = postSuccess(result)
            override fun onFail(code: Int) = postError(result, code, msg)
        }

    private fun boolValueCallback(result: MethodChannel.Result, msg: String) =
        object : BoolValueCallback() {
            override fun onSuccess(value: Boolean) = postSuccess(result, value)
            override fun onFail(code: Int) = postError(result, code, msg)
        }

    private fun intCallback(result: MethodChannel.Result, msg: String) =
        object : IntValueCallback() {
            override fun onSuccess(value: Int) = postSuccess(result, value)
            override fun onFail(code: Int) = postError(result, code, msg)
        }

    private fun handleCreateBond(result: MethodChannel.Result) =
        BluetoothSDK.createBond(voidCallback(result, "createBond failed"))

    private fun handleRemoveBond(result: MethodChannel.Result) =
        BluetoothSDK.removeBond(
            object : RemoveBondCallback() {
                override fun onSuccess() = postSuccess(result)
                override fun onFail(code: Int) = postError(result, code, "removeBond failed")
            },
        )

    private fun handleGetBtConnectionState(result: MethodChannel.Result) =
        BluetoothSDK.getBTConnectionState(boolValueCallback(result, "getBtConnectionState failed"))

    private fun handleSetBtSwitchWithAutoConnect(call: MethodCall, result: MethodChannel.Result) {
        val on = call.argument<Boolean>("on") == true
        val autoConnect = call.argument<Boolean>("autoConnect") == true
        val callback = boolCallback(result, "setBtSwitchWithAutoConnect failed")
        if (on) {
            BluetoothSDK.turnOnBTSwitchWithOption(autoConnect, callback)
        } else {
            BluetoothSDK.setBTSwitch(false, callback)
        }
    }

    private fun handleSetDeviceTime(call: MethodCall, result: MethodChannel.Result) {
        val timeMs = toLong(call.argument<Any>("timeMs"))
        val use24 = toInt(call.argument<Any>("use24HourFormat"), 1)
        BluetoothSDK.setDeviceTimeAndStyle(
            Date(timeMs),
            use24,
            boolCallback(result, "setDeviceTime failed"),
        )
    }

    private fun handleSetUserInfo(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "setUserInfo requires a map", null)
            return
        }
        val userInfo =
            UserInfo().apply {
                args["id"]?.let { id = it.toString() }
                gender = Gender.valueOf(toInt(args["gender"]))
                age = toInt(args["age"])
                height = toInt(args["height"])
                weight = toInt(args["weight"])
                if (args["birthdayYear"] != null) birthdayYear = toInt(args["birthdayYear"])
                if (args["birthdayMonth"] != null) birthdayMonth = toInt(args["birthdayMonth"])
                if (args["birthdayDay"] != null) birthdayDay = toInt(args["birthdayDay"])
            }
        BluetoothSDK.setUserInfo(userInfo, boolCallback(result, "setUserInfo failed"))
    }

    private fun handleSetUnit(call: MethodCall, result: MethodChannel.Result) {
        val unitValue = toInt(call.argument<Any>("unit"))
        BluetoothSDK.setUnit(Unit.valueOf(unitValue), boolCallback(result, "setUnit failed"))
    }

    private fun handleSetLanguage(call: MethodCall, result: MethodChannel.Result) {
        val languageCode =
            toInt(call.argument<Any>("language") ?: call.argument<Any>("languageCode"))
        val language = LanguageUtils.getLanguageCode(languageCode)
        BluetoothSDK.setLanguage(language, boolCallback(result, "setLanguage failed"))
    }

    private fun handleGetDeviceInfo(result: MethodChannel.Result) =
        BluetoothSDK.getDeviceInfo(
            object : DeviceInfoCallback() {
                override fun onSuccess(deviceInfo: DeviceInfo) =
                    postSuccess(result, deviceInfoMap(deviceInfo))

                override fun onFail(code: Int) = postError(result, code, "getDeviceInfo failed")
            },
        )

    private fun handleGetBindState(result: MethodChannel.Result) =
        BluetoothSDK.getBindState(intCallback(result, "getBindState failed"))

    private fun handleGetHealthDataCount(result: MethodChannel.Result) {
        BluetoothSDK.addDataTask(
            GetActivityNum(
                object : ActivityNumCallback() {
                    override fun onSuccess(activityNum: ActivityNum) =
                        postSuccess(
                            result,
                            mapOf(
                                "activityCount" to activityNum.sportNum,
                                "sleepCount" to activityNum.sleepNum,
                                "heartrateCount" to activityNum.heartrateNum,
                                "hrfCount" to activityNum.hrvNum,
                            ),
                        )

                    override fun onFail(code: Int) =
                        postError(result, code, "getHealthDataCount failed")
                },
            ),
        )
    }

    private fun handleGetActivities(call: MethodCall, result: MethodChannel.Result) {
        val count = toInt(call.argument<Any>("activityCount"))
        if (count <= 0) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }
        BluetoothSDK.addDataTask(
            GetSports(
                count,
                object : SportsCallback() {
                    override fun onSuccess(sportList: List<Sport>?) {
                        postSuccess(result, sportList?.map { activityMap(it) } ?: emptyList<Map<String, Any?>>())
                    }

                    override fun onFail(code: Int) =
                        postError(result, code, "getActivities failed")
                },
            ),
        )
    }

    private fun handleGetHeartrates(result: MethodChannel.Result) =
        BluetoothSDK.getHeartrates(
            object : HeartratesCallback() {
                override fun onSuccess(list: List<Heartrate>?) {
                    postSuccess(result, list?.map { heartrateMap(it) } ?: emptyList<Map<String, Any?>>())
                }

                override fun onFail(code: Int) = postError(result, code, "getHeartrates failed")
            },
        )

    private fun handleGetSleeps(result: MethodChannel.Result) =
        BluetoothSDK.getSleeps(
            object : SleepsCallback() {
                override fun onSuccess(list: List<Sleep>?) {
                    postSuccess(
                        result,
                        list?.mapIndexed { index, sleep -> sleepMap(index, sleep) }
                            ?: emptyList<Map<String, Any?>>(),
                    )
                }

                override fun onFail(code: Int) = postError(result, code, "getSleeps failed")
            },
        )

    private fun handleGetActivitiesV2(result: MethodChannel.Result) {
        val method = "getActivitiesV2"
        logWlEnter(method)
        BluetoothSDK.getStepV2(
            object : SportsCallback() {
                override fun onSuccess(list: List<Sport>?) {
                    try {
                        val mapped = list?.map { activityMap(it) } ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun handleGetSleepsV2(result: MethodChannel.Result) {
        val method = "getSleepsV2"
        logWlEnter(method)
        BluetoothSDK.getSleepV2(
            object : SleepsCallback() {
                override fun onSuccess(list: List<Sleep>?) {
                    try {
                        val mapped =
                            list?.mapIndexed { index, sleep -> sleepMap(index, sleep) }
                                ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun handleGetHeartratesV2(result: MethodChannel.Result) {
        val method = "getHeartratesV2"
        logWlEnter(method)
        BluetoothSDK.getHeartRateV2(
            object : HeartratesCallback() {
                override fun onSuccess(list: List<Heartrate>?) {
                    try {
                        val mapped = list?.map { heartrateMap(it) } ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun handleGetSpo2sV2(result: MethodChannel.Result) {
        val method = "getSpo2sV2"
        logWlEnter(method)
        BluetoothSDK.getSpo2V2(
            object : Spo2Callback() {
                override fun onSuccess(list: List<Spo2>?) {
                    try {
                        val mapped = list?.map { spo2Map(it) } ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun handleGetStressesV2(result: MethodChannel.Result) {
        val method = "getStressesV2"
        logWlEnter(method)
        BluetoothSDK.getStressV2(
            object : StressCallback() {
                override fun onSuccess(list: List<Stress>?) {
                    try {
                        val mapped = list?.map { stressMap(it) } ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun handleGetHrvsV2(result: MethodChannel.Result) {
        val method = "getHrvsV2"
        logWlEnter(method)
        BluetoothSDK.getHrvV2(
            object : HrvsCallback() {
                override fun onSuccess(list: List<Hrv>?) {
                    try {
                        val mapped = list?.map { hrvMap(it) } ?: emptyList()
                        logWlSuccess(method, mapped.size)
                        postSuccess(result, mapped)
                    } catch (error: Exception) {
                        postWlMappingError(result, method, error)
                    }
                }

                override fun onFail(code: Int) = postWlError(result, method, code)
            },
        )
    }

    private fun startScan(timeoutMs: Long) {
        if (!initialized) {
            emitScanError("NOT_INITIALIZED", "Call init() before scanDevices()")
            return
        }
        BluetoothSDK.scan(
            timeoutMs,
            object : ScanCallback() {
                override fun onStarted(success: Boolean) {
                    emitScanEvent(mapOf("event" to "scanStarted", "success" to success))
                }

                override fun onResult(bleDevice: Device) {
                    emitScanEvent(
                        mapOf("event" to "scanResult", "device" to deviceMap(bleDevice)),
                    )
                }

                override fun onFinished(resultList: List<Device>?) {
                    val devices = resultList?.map { deviceMap(it) } ?: emptyList()
                    emitScanEvent(mapOf("event" to "scanFinished", "devices" to devices))
                    mainHandler.post {
                        scanSink?.endOfStream()
                        scanSink = null
                    }
                }
            },
        )
    }

    private fun registerConnectionListener() {
        if (!initialized || connectionListenerRegistered) return
        BluetoothSDK.addConnectionStateListener(connectionStateCallback)
        connectionListenerRegistered = true
    }

    private fun unregisterConnectionListener() {
        if (!connectionListenerRegistered) return
        try {
            BluetoothSDK.removeConnectionStateListener(connectionStateCallback)
        } catch (_: Exception) {
        }
        connectionListenerRegistered = false
    }

    private fun emitConnectionEvent(connected: Boolean) {
        val sink = connectionSink ?: return
        val payload = mutableMapOf<String, Any?>("event" to if (connected) "connected" else "disconnected")
        if (connected) {
            BluetoothSDK.getConnectedDevice()?.let { device ->
                device.name?.let { payload["deviceName"] = it }
                device.mac?.let { payload["macAddress"] = it }
            }
        }
        mainHandler.post { sink.success(payload) }
    }

    private fun emitScanEvent(event: Map<String, Any?>) {
        mainHandler.post { scanSink?.success(event) }
    }

    private fun emitScanError(code: String, message: String) {
        mainHandler.post { scanSink?.error(code, message, null) }
    }

    private fun boolCallback(result: MethodChannel.Result, failMessage: String): BoolCallback =
        object : BoolCallback() {
            override fun onSuccess() = postSuccess(result)
            override fun onFail(code: Int) = postError(result, code, failMessage)
        }

    private inner class ScanStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            scanSink = events
            val timeoutMs =
                when (arguments) {
                    is Map<*, *> -> toLong(arguments["timeoutMs"], 8000L)
                    else -> 8000L
                }
            startScan(timeoutMs)
        }

        override fun onCancel(arguments: Any?) {
            BluetoothSDK.stopScan()
            scanSink = null
        }
    }

    private inner class ConnectionStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            connectionSink = events
            registerConnectionListener()
            mainHandler.post { emitConnectionEvent(BluetoothSDK.isConnected()) }
        }

        override fun onCancel(arguments: Any?) {
            connectionSink = null
        }
    }

    private fun deviceMap(device: Device): Map<String, Any?> =
        mapOf(
            "name" to device.name,
            "macAddress" to device.mac,
            "rssi" to device.rssi,
        )

    private fun deviceInfoMap(info: DeviceInfo): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "id" to info.id,
            "type" to info.type,
            "firmwareVersion" to info.firmwareVersion,
            "mac" to info.mac,
            "bindState" to info.bindState,
            "battery" to info.battery,
            "displayingWatchfaceId" to info.displayingWatchfaceId,
            "watchfaceVersion" to info.watchfaceVersion,
            "protocolVersion" to info.protocolVersion,
            "mapUuid" to info.mapUUID,
            "mapAuthorized" to info.isMapAuthorized,
        )
        info.language?.let { map["language"] = it.value }
        info.features?.let { bytes ->
            map["features"] = bytes.map { it.toInt() }
        }
        info.supportedLanguages?.let { langs ->
            map["supportedLanguages"] = langs.map { it.value }
        }
        return map
    }

    private fun activityMap(sport: Sport): Map<String, Any?> =
        mapOf(
            "index" to sport.index,
            "timeMs" to sport.time,
            "step" to sport.step,
            "calorie" to sport.calorie,
            "staticCalorie" to sport.staticCalorie,
            "distance" to sport.distance,
            "duration" to sport.duration,
            "avgBpm" to sport.heartAvg,
        )

    private fun heartrateMap(hr: Heartrate): Map<String, Any?> =
        mapOf(
            "index" to hr.index,
            "timeMs" to hr.time,
            "bpm" to hr.bpm,
        )

    private fun sleepMap(index: Int, sleep: Sleep): Map<String, Any?> =
        mapOf(
            "index" to index,
            "timeMs" to sleep.startTime,
            "deep" to sleep.deepDuration,
            "light" to sleep.lightDuration,
            "awake" to sleep.awakeDuration,
            "rem" to sleep.remDuration,
        )

    private fun spo2Map(spo2: Spo2): Map<String, Any?> =
        mapOf(
            "index" to spo2.index,
            "timeMs" to spo2.time,
            "spo2" to spo2.spo2,
        )

    private fun stressMap(stress: Stress): Map<String, Any?> =
        mapOf(
            "index" to stress.index,
            "timeMs" to stress.time,
            "stress" to stress.stress,
        )

    private fun hrvMap(hrv: Hrv): Map<String, Any?> =
        mapOf(
            "index" to hrv.index,
            "timeMs" to hrv.time,
            "fatigue" to hrv.fatigue,
        )

    private fun toInt(value: Any?, defaultValue: Int = 0): Int =
        when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Number -> value.toInt()
            else -> defaultValue
        }

    private fun toLong(value: Any?, defaultValue: Long = 0L): Long =
        when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Number -> value.toLong()
            else -> defaultValue
        }
}
