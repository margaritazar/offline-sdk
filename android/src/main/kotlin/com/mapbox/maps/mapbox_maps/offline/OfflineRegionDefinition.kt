package com.mapbox.maps.mapbox_maps.offline

import com.mapbox.geojson.*
import com.mapbox.maps.GlyphsRasterizationMode
import com.mapbox.turf.TurfConstants
import com.mapbox.turf.TurfMeasurement
import com.mapbox.turf.TurfTransformation
import java.lang.StrictMath.abs

class OfflineRegionDefinition(
  val geometry: Geometry,
  val mapStyleUrl: String,
  val minZoom: Double,
  val maxZoom: Double,
  val radius: Double,
  val metadata: Map<String, String>?,
  val id: String
) {
  companion object {
    fun fromDictionary(jsonDict: Map<String, Any>): OfflineRegionDefinition? {
      val radius = (jsonDict["radius"] as? Double) ?: 20000.0 // in m,
      val coordinates = jsonDict["coordinates"] as? List<List<Double>>? ?: return null
      val mapStyleString = jsonDict["mapStyleUrl"] as? String ?: return null
      val minZoom = jsonDict["minZoom"] as? Double ?: return null
      val maxZoom = jsonDict["maxZoom"] as? Double ?: return null
      val id = jsonDict["id"] as? String ?: return null
      val mode = jsonDict["geometry"] as? String ?: return null
      val calculatedGeometry = Converters.geometryConverter(mode, coordinates, radius) ?: return null

      return OfflineRegionDefinition(
        calculatedGeometry,
        mapStyleString,
        minZoom,
        maxZoom,
        radius,
        jsonDict["metadata"] as? Map<String, String>,
        id,
      )
    }
  }
}

class OfflineStyleDefinition(
  val mapStyleUrl: String,
  val mode: GlyphsRasterizationMode,
  val metadata: Map<String, String>?
) {

  companion object {
    fun fromDictionary(jsonDict: Map<String, Any>): OfflineStyleDefinition? {
      val mode = jsonDict["mode"] as? String ?: return null
      val mapStyleString = jsonDict["mapStyleUrl"] as? String ?: return null

      return OfflineStyleDefinition(
        mapStyleString,
        Converters.glyphConverter(mode),
        jsonDict["metadata"] as? Map<String, String>
      )
    }
  }
}

object Converters {
  fun glyphConverter(value: String): GlyphsRasterizationMode {
    return when (value) {
      "noGlyphsRasterizedLocally" -> GlyphsRasterizationMode.NO_GLYPHS_RASTERIZED_LOCALLY
      "allGlyphsRasterizedLocally" -> GlyphsRasterizationMode.ALL_GLYPHS_RASTERIZED_LOCALLY
      else -> GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY
    }
  }

  fun geometryConverter(value: String, coordinates: List<List<Double>>, radius: Double): Geometry? {
    return when (value) {
      "point" -> Point.fromLngLat(coordinates[0][0], coordinates[0][1])
      "lineString" -> LineString.fromLngLats(coordinates.map { Point.fromLngLat(it[0], it[1]) })
      "multiPolygon" -> MultiPolygon.fromPolygons(coordinates.map {
        TurfTransformation.circle(Point.fromLngLat(it[0], it[1]), radius, 4, TurfConstants.UNIT_METERS)
      })
      "polygon" -> {
        val polygon = Polygon.fromLngLats(listOf(coordinates.map { Point.fromLngLat(it[0], it[1]) }))
        val bbox = TurfMeasurement.bbox(polygon)
        val center = Point.fromLngLat(abs(bbox[2] - bbox[0]) / 2, abs(bbox[3] - bbox[1]) / 2)
        TurfTransformation.circle(center, radius, 4, TurfConstants.UNIT_METERS)
      }
      else -> null
    }
  }
}