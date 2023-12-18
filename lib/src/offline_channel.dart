part of mapbox_maps_flutter;

final MethodChannel _offlineChannel =
    MethodChannel('plugins.flutter.io/mapbox_maps');


Future<dynamic> setOffline(
  bool offline, {
  String? accessToken,
}) =>
    _offlineChannel.invokeMethod(
      'setOffline',
      <String, dynamic>{
        'offline': offline,
        'accessToken': accessToken,
      },
    );

Future<dynamic> downloadOfflineRegion(
  OfflineRegionDefinition definition, {
  Map<String, dynamic> metadata = const {},
  String? accessToken,
 //Function(DownloadRegionStatus event)? onEvent,
}) async {
  String channelName =
      'downloadOfflineRegion_${DateTime.now().microsecondsSinceEpoch}';

  final result = await _offlineChannel
      .invokeMethod('downloadOfflineRegion', <String, dynamic>{
    'accessToken': accessToken,
    'channelName': channelName,
    'definition': definition.toMap(),
    'metadata': metadata,
  });

  return result;
}