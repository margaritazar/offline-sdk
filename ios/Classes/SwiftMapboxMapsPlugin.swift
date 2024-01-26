import Flutter
import UIKit
import Foundation
import MapboxMaps

enum PluginErrors: String {
    case parsingError = "Parsing data error"
    case fetchingModelsError = "Fetching models error"
}

enum OfflineMethods: String {
    case startDownload = "downloadOfflineRegion"
    case getDownloadedRegionIds = "getDownloadedRegionIds"
    case cancelDownloading = "cancelDownloading"
    case deleteAllTilesAndStyles = "deleteAllTilesAndStyles"
    case deleteTilesById = "deleteTilesById"
}

public class SwiftMapboxMapsPlugin: MapboxMapsPlugin {
    
    override public static func register(with registrar: FlutterPluginRegistrar) {
        
        let defenitionKey = "definition"
        let styleKey = "style"
        let channelNameKey = "channelName"
        let accessTokenKey = "accessToken"
        let idsKey = "ids"
        
        
        let instance = MapboxMapFactory(withRegistrar: registrar)
        registrar.register(instance, withId: "plugins.flutter.io/mapbox_maps")
        
        let channel = FlutterMethodChannel(name: "plugins.flutter.io/mapbox_maps", binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler { methodCall, result  in
            switch methodCall.method {
                
            case OfflineMethods.startDownload.rawValue:
                
                let definition = (methodCall.arguments as? [String: Any])?[defenitionKey] as? [String: Any]
                let style = (
                    methodCall.arguments as? [String: Any])?[styleKey] as? [String: Any]
                let channelName = (
                    methodCall.arguments as? [String: Any])?[channelNameKey] as? String
                let accessToken = (
                    methodCall.arguments as? [String: Any])?[accessTokenKey] as? String
                
                guard let definition = definition, let style = style else {
                    result(PluginErrors.fetchingModelsError.rawValue)
                    return;
                }
                
                let region = OfflineRegionDefinition.fromDictionary(definition)
                let regionStyle = OfflineStyleDefinition.fromDictionary(style)
                
                guard let region = region, let regionStyle = regionStyle, let channelName = channelName, let accessToken = accessToken else {
                    result(PluginErrors.parsingError.rawValue)
                    return;
                }
                
                let channelHandler = OfflineChannelHandler(
                    messenger: registrar.messenger(),
                    channelName: channelName
                )
                OfflineManagerInterface.sharedInstance.downloadTileRegions(region: region, style: regionStyle, channel: channelHandler, flutterResult: result, accessToken: accessToken)
                
                
            case OfflineMethods.getDownloadedRegionIds.rawValue:
                OfflineManagerInterface.sharedInstance.getDownloadedRegionsIds(flutterResult: result)
                
            case OfflineMethods.deleteTilesById.rawValue:
                let ids = (methodCall.arguments as? [String: Any])?[idsKey] as? Array<String>
                OfflineManagerInterface.sharedInstance.deleteTilesPackByIds(ids: ids ?? [], flutterResult: result)
                
                
            case OfflineMethods.cancelDownloading.rawValue:
                OfflineManagerInterface.sharedInstance.cancelDownloads(flutterResult: result)
                
                
            case OfflineMethods.deleteAllTilesAndStyles.rawValue:
                let accessToken = (
                    methodCall.arguments as? [String: Any])?[accessTokenKey] as? String
                
                guard let accessToken = accessToken else {
                    result(PluginErrors.parsingError.rawValue)
                    return;
                }
                
                
                OfflineManagerInterface.sharedInstance.deleteAllTilesAndStyles(flutterResult: result, accessToken: accessToken)
                
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
