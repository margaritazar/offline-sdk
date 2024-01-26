package com.mapbox.maps.mapbox_maps

import androidx.lifecycle.Lifecycle
import com.mapbox.maps.mapbox_maps.offline.OfflineChannelHandler
import com.mapbox.maps.mapbox_maps.offline.OfflineRegionDefinition
import com.mapbox.maps.mapbox_maps.offline.OfflineStyleDefinition
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private enum class PluginErrors(val key: String) {
  PARSING_ERROR("Parsing data error"),
  FETCHING_MODELS_ERROR("Fetching models error")
}

private enum class OfflineMethods(val key: String) {
  START_DOWNLOAD("downloadOfflineRegion"),
  GET_DOWNLOADED_REGION_IDS("getDownloadedRegionIds"),
  CANCEL_DOWNLOADING("cancelDownloading"),
  DELETE_ALL_TILES_AND_STYLES("deleteAllTilesAndStyles"),
  DELETE_TILES_BY_ID("deleteTilesById")
}

/** MapboxMapsPlugin */
class MapboxMapsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

  private companion object {
    private const val DEFINITION_KEY = "definition"
    private const val STYLE_KEY = "style"
    private const val CHANNEL_NAME_KEY = "channelName"
    private const val ACCESS_TOKEN_KEY = "accessToken"
    private const val IDS_KEY = "ids"
  }

  private var lifecycle: Lifecycle? = null

  // / The MethodChannel that will the communication between Flutter and native Android
  // /
  // / This local reference serves to register the plugin with the Flutter Engine and unregister it
  // / when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "plugins.flutter.io/mapbox_maps")
    channel.setMethodCallHandler(this)
    flutterPluginBinding
      .platformViewRegistry
      .registerViewFactory(
        "plugins.flutter.io/mapbox_maps",
        MapboxMapFactory(
          flutterPluginBinding.binaryMessenger,
          object : LifecycleProvider {
            override fun getLifecycle(): Lifecycle? {
              return lifecycle
            }
          }
        )
      )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    try {
      when (call.method) {
        OfflineMethods.START_DOWNLOAD.key -> {
          val flutterPluginBinding = flutterPluginBinding
          if (flutterPluginBinding == null) {
            result.success(PluginErrors.FETCHING_MODELS_ERROR.key)
            return
          }
          val definition = call.argument<Map<String, Any>>(DEFINITION_KEY)
          val style = call.argument<Map<String, Any>>(STYLE_KEY)
          val channelName = call.argument<String>(CHANNEL_NAME_KEY)
          val accessToken = call.argument<String>(ACCESS_TOKEN_KEY)
          if (definition == null || style == null) {
            result.success(PluginErrors.FETCHING_MODELS_ERROR.key)
            return
          }

          val region = OfflineRegionDefinition.fromDictionary(definition)
          val regionStyle = OfflineStyleDefinition.fromDictionary(style)

          if (region == null || regionStyle == null || channelName == null || accessToken == null) {
            result.success(PluginErrors.PARSING_ERROR.key)
            return
          }

          OfflineManagerInterface.downloadTileRegions(
            region,
            regionStyle,
            OfflineChannelHandler(flutterPluginBinding.binaryMessenger, channelName),
            accessToken
          ).let {
            result.success(it.key)
          }
        }
        OfflineMethods.GET_DOWNLOADED_REGION_IDS.key ->
          OfflineManagerInterface.getDownloadedRegionsIds { it, list ->
            result.success(if (it == OfflineResult.SUCCESS) list else it.key)
          }

        OfflineMethods.DELETE_TILES_BY_ID.key ->
          OfflineManagerInterface.deleteTilesPackByIds(call.argument<List<String>>(IDS_KEY) ?: emptyList()).let {
            result.success(it.key)
          }

        OfflineMethods.CANCEL_DOWNLOADING.key ->
          OfflineManagerInterface.cancelDownloads().let {
            result.success(it.key)
          }

        OfflineMethods.DELETE_ALL_TILES_AND_STYLES.key -> {
          val accessToken = call.argument<String>(ACCESS_TOKEN_KEY)
          if (accessToken == null) {
            result.success(PluginErrors.FETCHING_MODELS_ERROR.key)
            return
          }
          OfflineManagerInterface.deleteAllTilesAndStyles(accessToken) {
            result.success(it.key)
          }
        }
        else -> result.notImplemented()
      }
    } catch (e: ClassCastException) {
      result.success(PluginErrors.FETCHING_MODELS_ERROR.key)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    lifecycle = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
  }

  override fun onDetachedFromActivity() {
    lifecycle = null
  }

  interface LifecycleProvider {
    fun getLifecycle(): Lifecycle?
  }
}