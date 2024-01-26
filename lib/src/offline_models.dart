part of mapbox_maps_flutter;

/// Description of region to be downloaded.
class OfflineRegionDefinition {
  const OfflineRegionDefinition(
      {required this.coordinates,
      required this.geometry,
      required this.mapStyleUrl,
      required this.minZoom,
      required this.maxZoom,
      required this.id,
      this.radius,
      this.metadata});

  final List<Position> coordinates;
  final GeoJSONObjectType geometry;
  final String mapStyleUrl;
  final double minZoom;
  final double maxZoom;
  final double? radius;
  final String? metadata;
  final String id;

  @override
  String toString() =>
      "$runtimeType,id =$id, bounds = $coordinates, mapStyleUrl = $mapStyleUrl, minZoom = $minZoom, maxZoom = $maxZoom, geometry = $geometry, radius = $radius, metadata = $metadata";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    // [Lng, Lat] order 
    data['coordinates'] = coordinates.map((e) => e.toJson()).toList();
    data['mapStyleUrl'] = mapStyleUrl;
    data['minZoom'] = minZoom;
    data['maxZoom'] = maxZoom;
    data['radius'] = radius;
    data['id'] = id;
    data['metadata'] = metadata;
    data['geometry'] = geometry.name;
    return data;
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
}

/// Description of a downloaded region including its identifier.
class OfflineRegionModel {
  const OfflineRegionModel({
    required this.definition,
    required this.style,
  });

  final OfflineRegionDefinition definition;
  final OfflineStyleDefinition style;

  @override
  String toString() => "$runtimeType, definition = $definition, metadata = $style";
}

class MockData {
  static OfflineRegionDefinition get mockRegionDefenition => OfflineRegionDefinition(
          coordinates: [
            Position(45.246905083937826, 19.81805587010649),
            Position(45.25110678492973, 19.81745749402151),
          ],
          mapStyleUrl: "mapbox://styles/mapbox/streets-v12",
          minZoom: 0,
          maxZoom: 16,
          geometry: GeoJSONObjectType.polygon,
          id: DateTime.now().millisecondsSinceEpoch.toString());

  static OfflineStyleDefinition get mockStyleDefenition =>
      OfflineStyleDefinition(mode: GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY, mapStyleUrl: "mapbox://styles/mapbox/streets-v12");
}
