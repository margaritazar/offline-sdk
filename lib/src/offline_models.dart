part of mapbox_maps_flutter;

/// Description of region to be downloaded.
class OfflineRegionDefinition {
  const OfflineRegionDefinition(
      {required this.coordinates,
      required this.geometry,
      required this.mapStyleUrl,
      required this.minZoom,
      required this.maxZoom,
      this.includeIdeographs = false,
      required this.id,
      this.metadata});

  final List<LatLng> coordinates;
  final GeoJSONObjectType geometry;
  final String mapStyleUrl;
  final double minZoom;
  final double maxZoom;
  final bool includeIdeographs;
  final String? metadata;
  final String id;

  @override
  String toString() =>
      "$runtimeType,id =$id, bounds = $coordinates, mapStyleUrl = $mapStyleUrl, minZoom = $minZoom, maxZoom = $maxZoom, geometry = $geometry, metadata = $metadata";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['coordinates'] = coordinates.map((e) => e.toJson()).toList();
    data['mapStyleUrl'] = mapStyleUrl;
    data['minZoom'] = minZoom;
    data['maxZoom'] = maxZoom;
    data['includeIdeographs'] = includeIdeographs;
    data['id'] = id;
    data['metadata'] = metadata;
    data['geometry'] = geometry.name;
    return data;
  }

  factory OfflineRegionDefinition.fromMap(Map<String, dynamic> map) {
    return OfflineRegionDefinition(
        coordinates: _latLngBoundsFromList(map['coordinates']),
        mapStyleUrl: map['mapStyleUrl'],
        minZoom: map['minZoom'].toDouble(),
        maxZoom: map['maxZoom'].toDouble(),
        includeIdeographs: map['includeIdeographs'] ?? false,
        geometry: map['geometry'],
        id: map['id']);
  }

  static List<LatLng> _latLngBoundsFromList(List<dynamic> json) {
    return [LatLng(json[0][0], json[0][1]), LatLng(json[1][0], json[1][1])];
  }
}

class OfflineStyleDefinition {
  const OfflineStyleDefinition({required this.mode, required this.mapStyleUrl, this.metadata});

  final GlyphsRasterizationMode mode;
  final String mapStyleUrl;
  final String? metadata;

  @override
  String toString() => "$runtimeType,mode =$mode, mapStyleUrl = $mapStyleUrl, metadata = $metadata";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['mode'] = mode.toString();
    data['mapStyleUrl'] = mapStyleUrl;
    data['metadata'] = metadata;
    return data;
  }

  factory OfflineStyleDefinition.fromMap(Map<String, dynamic> map) {
    return OfflineStyleDefinition(mode: map['mode'], mapStyleUrl: map['mapStyleUrl'], metadata: map['metadata']);
  }
}

/// Description of a downloaded region including its identifier.
class OfflineRegionModel {
  const OfflineRegionModel({
    required this.definition,
    required this.style,
  });

  final OfflineRegionDefinition definition;
  final OfflineStyleDefinition style;

  factory OfflineRegionModel.fromMap(Map<String, dynamic> json) {
    return OfflineRegionModel(
      definition: OfflineRegionDefinition.fromMap(json['definition']),
      style: OfflineStyleDefinition.fromMap(json['style']),
    );
  }

  @override
  String toString() => "$runtimeType, definition = $definition, metadata = $style";
}

class MockData {
  static OfflineRegionDefinition get mockRegionDefenition => OfflineRegionDefinition(
          coordinates: [
            LatLng(45.246905083937826, 19.81805587010649),
            LatLng(45.25110678492973, 19.81745749402151),
          ],
          mapStyleUrl: "mapbox://styles/mapbox/streets-v12",
          minZoom: 0,
          maxZoom: 16,
          includeIdeographs: false,
          geometry: GeoJSONObjectType.polygon,
          id: DateTime.now().millisecondsSinceEpoch.toString());

  static OfflineStyleDefinition get mockStyleDefenition =>
      OfflineStyleDefinition(mode: GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY, mapStyleUrl: "mapbox://styles/mapbox/streets-v12");
}
