import Flutter
import UIKit
import Foundation
import MapboxMaps

public class SwiftMapboxMapsPlugin: MapboxMapsPlugin {
    
    override public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MapboxMapFactory(withRegistrar: registrar)
        registrar.register(instance, withId: "plugins.flutter.io/mapbox_maps")

        let channel = FlutterMethodChannel(name: "plugins.flutter.io/mapbox_maps", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { methodCall, result  in
            print("method ${methodCall.method}")
            switch methodCall.method {
            //case "setOffline": result("Success");
            case "downloadOfflineRegion": OfflineManagerInterface.sharedInstance.downloadTileRegions()
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
