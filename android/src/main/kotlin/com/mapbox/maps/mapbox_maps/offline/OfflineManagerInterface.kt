import android.util.Log
import com.mapbox.bindgen.Expected
import com.mapbox.bindgen.Value
import com.mapbox.common.*
import com.mapbox.maps.*
import com.mapbox.maps.mapbox_maps.offline.OfflineChannelHandler
import com.mapbox.maps.mapbox_maps.offline.OfflineRegionDefinition
import com.mapbox.maps.mapbox_maps.offline.OfflineStyleDefinition
import kotlinx.coroutines.*
import kotlin.coroutines.suspendCoroutine

enum class OfflineResult(val key: String) {
  FAILED("Failed"),
  SUCCESS("Success")
}

object OfflineManagerInterface {

  private const val TAG = "OfflineManagerInterface"

  private var tileStore: TileStore? = null
  private var offlineManager: OfflineManager? = null
  private var downloads = mutableListOf<Cancelable>()
  private var channels = mutableListOf<OfflineChannelHandler>()
  private val scope = MainScope()

  init {
    tileStore = TileStore.create()
  }

  fun downloadTileRegions(
    region: OfflineRegionDefinition,
    style: OfflineStyleDefinition,
    channel: OfflineChannelHandler,
    accessToken: String
  ): OfflineResult {
    if (offlineManager == null) {
      offlineManager = OfflineManager(ResourceOptions.Builder().accessToken(accessToken).build())
    }

    val tileStore = tileStore ?: return OfflineResult.FAILED
    val offlineManager = offlineManager ?: return OfflineResult.FAILED

    if (downloads.isNotEmpty()) {
      Log.v(TAG, "Downloading is in process")
      return OfflineResult.FAILED
    }
    channels.add(channel)
    scope.launch(Dispatchers.Default) {
      // 1. Create style package with loadStylePack() call.
      val styles = async { awaitLoadStylePack(style, channel, offlineManager) }
      // 2. Create an offline region with tiles for the outdoors style
      val regions = async { awaitLoadTails(region, channel, offlineManager, tileStore) }
      val isSuccessful = styles.await() && regions.await()
      launch(Dispatchers.Main) {
        downloads = mutableListOf()
        channels = mutableListOf()
        if (isSuccessful) {
          channel.onSuccess()
        } else {
          channel.onError("offlineRegionLoadFailure", "Something went wrong", null)
        }
      }
    }
    return OfflineResult.SUCCESS
  }

  private suspend fun awaitLoadStylePack(
    style: OfflineStyleDefinition,
    channel: OfflineChannelHandler,
    offlineManager: OfflineManager
  ): Boolean =
    suspendCoroutine { continuation ->
      Log.v(TAG, "Create style package with loadStylePack() call.")
      val stylePackLoadOptions = StylePackLoadOptions.Builder()
        .glyphsRasterizationMode(style.mode)
        .metadata(if (style.metadata != null) Value.valueOf(style.metadata.mapValuesTo(HashMap()) { Value.valueOf(it.value) }) else null)
        .build()
      val onProgress: (StylePackLoadProgress) -> Unit = { progress ->
        scope.launch(Dispatchers.Main) {
          channel.onStyleProgress(if (progress.requiredResourceCount == 0L) 0.0 else (progress.completedResourceCount.toDouble() / progress.requiredResourceCount.toDouble()))
        }
      }
      val onFinish: (Expected<StylePackError, StylePack>) -> Unit = {
        scope.launch(Dispatchers.Main) {
          Log.v(TAG, "Style download: ${if (it.isError) it.error?.message else "Success"}")
          if (it.isError) {
            channel.onError("offlineStyleLoadFailure", it.error?.message, null)
            continuation.resumeWith(Result.success(false))
          } else {
            continuation.resumeWith(Result.success(true))
          }
        }
      }
      scope.launch(Dispatchers.Main) {
        try {
          downloads.add(offlineManager.loadStylePack(style.mapStyleUrl, stylePackLoadOptions, onProgress, onFinish))
        } catch (e: Exception) {
          Log.v(TAG, "Start style download exception: ${e.message}")
          continuation.resumeWith(Result.success(false))
        }
      }
    }

  private suspend fun awaitLoadTails(
    region: OfflineRegionDefinition,
    channel: OfflineChannelHandler,
    offlineManager: OfflineManager,
    tileStore: TileStore
  ): Boolean = suspendCoroutine { continuation ->
    Log.v(TAG, "Create an offline region with tiles for the outdoors style")
    val outdoorsOptions = TilesetDescriptorOptions.Builder()
      .styleURI(region.mapStyleUrl)
      .minZoom(region.minZoom.toInt().toByte())
      .maxZoom(region.maxZoom.toInt().toByte())
      .build()
    val onProgress: (TileRegionLoadProgress) -> Unit = {
      scope.launch(Dispatchers.Main) {
        channel.onTileProgress(if (it.requiredResourceCount == 0L) 0.0 else (it.completedResourceCount.toDouble() / it.requiredResourceCount.toDouble()))
      }
    }
    val onFinish: (Expected<TileRegionError, TileRegion>) -> Unit = {
      scope.launch(Dispatchers.Main) {
        Log.v(TAG, "tile download: ${if (it.isError) it.error?.message else "Success"}")
        if (it.isError) {
          channel.onError("offlineTilesLoadFailure", it.error?.message, null)
          continuation.resumeWith(Result.success(false))
        } else {
          continuation.resumeWith(Result.success(true))
        }
      }
    }
    scope.launch(Dispatchers.Main) {
      val outdoorsDescriptor = offlineManager.createTilesetDescriptor(outdoorsOptions)

      // Load the tile region
      val tileRegionLoadOptions = TileRegionLoadOptions.Builder()
        .geometry(region.geometry)
        .descriptors(listOf(outdoorsDescriptor))
        .metadata(if (region.metadata != null) Value.valueOf(region.metadata.mapValuesTo(HashMap()) { Value.valueOf(it.value) }) else null)
        .acceptExpired(true)
        .build()
      try {
        downloads.add(tileStore.loadTileRegion(region.id, tileRegionLoadOptions, onProgress, onFinish))
      } catch (e: Exception) {
        Log.v(TAG, "Start style download exception: ${e.message}")
        continuation.resumeWith(Result.success(true))
      }
    }
  }

  fun getDownloadedRegionsIds(callback: (OfflineResult, List<String>?) -> Unit) {
    val tileStore = tileStore
    if (tileStore == null) {
      callback(OfflineResult.FAILED, null)
      return
    }
    tileStore.getAllTileRegions {
      callback(if (it.isError) OfflineResult.FAILED else OfflineResult.SUCCESS, it.value?.map { region -> region.id })
    }
  }

  fun cancelDownloads(): OfflineResult {
    return try {
      downloads.forEach { it.cancel() }
      channels.forEach { it.onCancel(null) }
      OfflineResult.SUCCESS
    } catch (e: Exception) {
      Log.v(TAG, "Cancel download exception: ${e.message}")
      OfflineResult.FAILED
    }
  }

  fun deleteTilesPackByIds(ids: List<String>): OfflineResult {
    val tileStore = tileStore ?: return OfflineResult.FAILED
    for (id in ids) {
      tileStore.removeTileRegion(id)
    }
    return OfflineResult.SUCCESS
  }

  // Remove downloaded region and style pack
  fun deleteAllTilesAndStyles(accessToken: String, callback: (OfflineResult) -> Unit) {
    if (offlineManager == null) {
      offlineManager = OfflineManager(ResourceOptions.Builder().accessToken(accessToken).build())
    }

    val tileStore = tileStore
    val offlineManager = offlineManager
    if (tileStore == null || offlineManager == null) {
      callback(OfflineResult.FAILED)
      return
    }

    scope.launch(Dispatchers.Default) {
      val styles = async { awaitStylesRemove(offlineManager) }
      val regions = async { awaitRegionsRemove(tileStore) }
      val isSuccessful = styles.await() && regions.await()
      callback(if (isSuccessful) OfflineResult.SUCCESS else OfflineResult.FAILED)
    }
  }


  private suspend fun awaitStylesRemove(offlineManager: OfflineManager): Boolean = suspendCoroutine { continuation ->
    scope.launch(Dispatchers.Main) {
      offlineManager.getAllStylePacks {
        if (it.isError) {
          Log.v(TAG, it.error?.message ?: "error")
          continuation.resumeWith(Result.success(true))
        } else {
          val list = it.value
          if (list != null) {
            scope.launch(Dispatchers.Main) {
              for (style in list) {
                Log.v(TAG, "remove style: ${style.styleURI}")
                offlineManager.removeStylePack(style.styleURI)
              }
            }
          }
          continuation.resumeWith(Result.success(false))
        }
      }
    }
  }

  private suspend fun awaitRegionsRemove(tileStore: TileStore): Boolean = suspendCoroutine { continuation ->
    scope.launch(Dispatchers.Main) {
      tileStore.getAllTileRegions {
        if (it.isError) {
          Log.v(TAG, it.error?.message ?: "error")
          continuation.resumeWith(Result.success(true))
        } else {
          val list = it.value
          if (list != null) {
            scope.launch(Dispatchers.Main) {
              for (region in list) {
                Log.v(TAG, "remove region: ${region.id}")
                tileStore.removeTileRegion(region.id)
              }
              tileStore.setOption(TileStoreOptions.DISK_QUOTA, Value.valueOf(0))
            }
          }
          continuation.resumeWith(Result.success(false))
        }
      }
    }
  }
}
