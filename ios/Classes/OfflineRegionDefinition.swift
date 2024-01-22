//
//  OfflineRegionDefinition.swift
//  mapbox_maps_flutter
//
//  Created by Margarita Zarubina on 19.12.2023.
//

import Foundation
import MapboxMaps

class OfflineRegionDefinition {
    let coordinates: Array<Array<Double>>
    let geometry: Geometry
    let mapStyleUrl: StyleURI
    let minZoom: Double
    let maxZoom: Double
    let radius: Double
    let metadata: [String : String]?
    let id: String
    
    init(coordinates: Array<Array<Double>>, mapStyleUrl: StyleURI, minZoom: Double, maxZoom: Double, metadata: [String : String]?, geometry: Geometry, id: String, radius: Double) {
        self.coordinates = coordinates
        self.geometry = geometry
        self.mapStyleUrl = mapStyleUrl
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.metadata = metadata
        self.id = id
        self.radius = radius
    }
    
    static func fromDictionary(_ jsonDict: [String: Any]) -> OfflineRegionDefinition? {
        let radius = (jsonDict["radius"] as? Double) ?? 20000 // in m,
        
        guard let coordinates = jsonDict["coordinates"] as? Array<Array<Double>>,
              let mapStyleString = jsonDict["mapStyleUrl"] as? String,
              let minZoom = jsonDict["minZoom"] as? Double,
              let maxZoom = jsonDict["maxZoom"] as? Double,
              let id = jsonDict["id"] as? String,
              let mode = jsonDict["geometry"] as? String,
              let calculatedGeometry = Converters.geometryConverter(value: mode, coordinates: coordinates, radius: radius),
              let mapStyleUrl = StyleURI(rawValue: mapStyleString)
        else { return nil }
        return OfflineRegionDefinition(
            coordinates: coordinates,
            mapStyleUrl: mapStyleUrl,
            minZoom: minZoom,
            maxZoom: maxZoom,
            metadata: jsonDict["metadata"] as? [String: String],
            geometry: calculatedGeometry,
            id: id,
            radius: radius
        )
    }
}

class OfflineStyleDefinition {
    let mapStyleUrl: StyleURI
    let mode: GlyphsRasterizationMode
    let metadata: [String : String]?
    
    init(mode: GlyphsRasterizationMode?, mapStyleUrl: StyleURI,metadata : [String : String]?) {
        self.mode = mode ?? .ideographsRasterizedLocally
        self.mapStyleUrl = mapStyleUrl
        self.metadata = metadata
    }
    
    static func fromDictionary(_ jsonDict: [String: Any]) -> OfflineStyleDefinition? {
        guard let mode = jsonDict["mode"] as? String,
              let mapStyleString = jsonDict["mapStyleUrl"] as? String,
              let mapStyleUrl = StyleURI(rawValue: mapStyleString)
        else { return nil }
        return OfflineStyleDefinition(
            mode: Converters.glyphConverter(value: mode),
            mapStyleUrl: mapStyleUrl,
            metadata: jsonDict["metadata"] as? [String: String]
        )
    }
    
    
}

class Converters {
    static func glyphConverter(value: String) -> GlyphsRasterizationMode {
        switch(value){
        case "noGlyphsRasterizedLocally": return .noGlyphsRasterizedLocally
        case "allGlyphsRasterizedLocally": return .allGlyphsRasterizedLocally
        default: return .ideographsRasterizedLocally
        }
    }
    
    static func geometryConverter(value: String, coordinates: Array<Array<Double>>, radius: Double) -> Geometry? {
        switch(value){
        case "point": return .point(Point(LocationCoordinate2D(latitude: coordinates[0][0], longitude: coordinates[0][1])))
        case "lineString": return .lineString(LineString([LocationCoordinate2D(latitude: coordinates[0][0], longitude: coordinates[0][1]), LocationCoordinate2D(latitude: coordinates[1][0], longitude: coordinates[1][1])]))
        case "multiPoint": return .multiPoint(MultiPoint(coordinates.map { (coord) -> LocationCoordinate2D in
            return LocationCoordinate2D(latitude: coord[0], longitude: coord[1])
        }))
        case "multiPolygon":
            return .multiPolygon(MultiPolygon(coordinates.map { (coord) -> Polygon in
                return Polygon(center: CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1]), radius: radius, vertices: 4)
            }))
        case "polygon": do {
            let center = Polygon(coordinates.map { (coord) -> [CLLocationCoordinate2D] in
                return [CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])]
                
            }).center
            return .polygon(Polygon(center: center ?? LocationCoordinate2D(latitude: coordinates[0][0], longitude: coordinates[0][1]), radius: radius, vertices: 4))
        }
            
        default: return nil
        }
    }
}
