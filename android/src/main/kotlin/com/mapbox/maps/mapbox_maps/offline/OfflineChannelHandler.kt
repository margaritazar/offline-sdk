package com.mapbox.maps.mapbox_maps.offline

import com.google.gson.JsonObject
import com.google.gson.JsonPrimitive
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

class OfflineChannelHandler(messenger: BinaryMessenger, channelName: String) : EventChannel.StreamHandler {
  private var sink: EventChannel.EventSink? = null

  init {
    val eventChannel = EventChannel(messenger, channelName)
    eventChannel.setStreamHandler(this)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    sink = events
  }

  override fun onCancel(arguments: Any?) {
    sink = null
  }

  fun onError(errorCode: String, errorMessage: String?, errorDetails: Any?) {
    sink?.error(errorCode, errorMessage, errorDetails)
  }

  fun onSuccess() {
    val json = JsonObject()
    json.add("status", JsonPrimitive("success"))
    sink?.success(json.toString())
  }

  fun onStart() {
    val json = JsonObject();
    json.add("status", JsonPrimitive("start"))
    sink?.success(json.toString())
  }

  fun onStyleProgress(progress: Double) {
    val json = JsonObject();
    json.add("status", JsonPrimitive("styleProgress"))
    json.add("progress", JsonPrimitive(progress))
    sink?.success(json.toString())
  }

  fun onTileProgress(progress: Double) {
    val json = JsonObject();
    json.add("status", JsonPrimitive("tileProgress"))
    json.add("progress", JsonPrimitive(progress))
    sink?.success(json.toString())
  }
}