part of mapbox_maps_flutter;

final MethodChannel _offlineChannel = MethodChannel('plugins.flutter.io/mapbox_maps');

Future<dynamic> downloadOfflineRegion(OfflineRegionDefinition definition, OfflineStyleDefinition style,
    {Map<String, dynamic> metadata = const {}, required String accessToken, required String channelName}) async {
  final result = await _offlineChannel.invokeMethod('downloadOfflineRegion', <String, dynamic>{
    'accessToken': accessToken,
    'channelName': channelName,
    'definition': definition.toMap(),
    'style': style.toMap(),
  });

  return result;
}

Future<List<String>?> getDownloadedRegionsIds() async {
  return _offlineChannel
      .invokeMethod(
    'getDownloadedRegionIds',
  )
      .then((value) {
    var valueList = (value as List?)?.map((e) => e.toString()).toList();
    return valueList;
  });
}

Future<dynamic> deleteTilesByIds(
  List<String> ids,
) {
  return _offlineChannel.invokeMethod('deleteTilesById', <String, dynamic>{
    'ids': ids,
  });
}

Future<dynamic> deleteAllTilesAndStyles({required String accessToken}) {
  return _offlineChannel.invokeMethod('deleteAllTilesAndStyles', <String, dynamic>{
    'accessToken': accessToken,
  });
}

Future<void> cancelDownload() {
  return _offlineChannel.invokeMethod('cancelDownloading');
}
