part of mapbox_maps_flutter;

/// Description of region to be downloaded. Identifier will be generated when the download is initiated.
class OfflineRegionDefinition {
  const OfflineRegionDefinition({
    required this.bounds,
    required this.mapStyleUrl,
    required this.minZoom,
    required this.maxZoom,
    this.includeIdeographs = false,
  });

  final LatLngBounds bounds;
  final String mapStyleUrl;
  final double minZoom;
  final double maxZoom;
  final bool includeIdeographs;

  @override
  String toString() =>
      "$runtimeType, bounds = $bounds, mapStyleUrl = $mapStyleUrl, minZoom = $minZoom, maxZoom = $maxZoom";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['bounds'] = bounds.toList();
    data['mapStyleUrl'] = mapStyleUrl;
    data['minZoom'] = minZoom;
    data['maxZoom'] = maxZoom;
    data['includeIdeographs'] = includeIdeographs;
    return data;
  }

  factory OfflineRegionDefinition.fromMap(Map<String, dynamic> map) {
    return OfflineRegionDefinition(
      bounds: _latLngBoundsFromList(map['bounds']),
      mapStyleUrl: map['mapStyleUrl'],
      minZoom: map['minZoom'].toDouble(),
      maxZoom: map['maxZoom'].toDouble(),
      includeIdeographs: map['includeIdeographs'] ?? false,
    );
  }

  static LatLngBounds _latLngBoundsFromList(List<dynamic> json) {
    return LatLngBounds(
      southwest: LatLng(json[0][0], json[0][1]),
      northeast: LatLng(json[1][0], json[1][1]),
    );
  }
}

/// Description of a downloaded region including its identifier.
class OfflineRegionModel {
  const OfflineRegionModel({
    required this.id,
    required this.definition,
    required this.metadata,
  });

  final int id;
  final OfflineRegionDefinition definition;
  final Map<String, dynamic> metadata;

  factory OfflineRegionModel.fromMap(Map<String, dynamic> json) {
    return OfflineRegionModel(
      id: json['id'],
      definition: OfflineRegionDefinition.fromMap(json['definition']),
      metadata: json['metadata'],
    );
  }

  @override
  String toString() =>
      "$runtimeType, id = $id, definition = $definition, metadata = $metadata";
}


class MockData {
  static OfflineRegionDefinition get mockRegionDefenition => OfflineRegionDefinition(
    bounds: LatLngBounds(southwest: LatLng(0.0, 0.0), northeast: LatLng(180.0, 180.0)),
    mapStyleUrl: "",
    minZoom: 0,
    maxZoom: 16,
   includeIdeographs: false
  );

  static OfflineRegionModel get model => OfflineRegionModel(
    id: 0,
    definition: MockData.mockRegionDefenition,
    metadata: {}
  );
}
