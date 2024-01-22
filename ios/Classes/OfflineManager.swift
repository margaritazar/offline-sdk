import Foundation
import UIKit
import MapboxMaps

enum OfflineResult: String {
    case failed = "Failed"
    case success = "Success"
}


final class OfflineManagerInterface {
    
    private var tileStore: TileStore? = TileStore.default
    static let sharedInstance: OfflineManagerInterface = OfflineManagerInterface()
    
    private var offlineManager: OfflineManager?
    private var downloads: [Cancelable] = []
    private var channels: [OfflineChannelHandler] = []
    
    
    func downloadTileRegions(region : OfflineRegionDefinition, style: OfflineStyleDefinition, channel: OfflineChannelHandler, flutterResult: FlutterResult, accessToken: String) {
        
        if (offlineManager == nil) {
            offlineManager = OfflineManager.init(resourceOptions: ResourceOptions(accessToken:  accessToken))
        }
        
        guard let tileStore = tileStore, let offlineManager = offlineManager else {
            return flutterResult(OfflineResult.failed.rawValue)
        }
        
        if (!downloads.isEmpty) {
            return flutterResult(OfflineResult.failed.rawValue)
        }
        
        let dispatchGroup = DispatchGroup()
        var downloadError = false
        
        flutterResult(OfflineResult.success.rawValue)
        
        // 1. Create style package with loadStylePack() call.
        let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: style.mode)!
        
        dispatchGroup.enter()
        let stylePackDownload = offlineManager.loadStylePack(for: style.mapStyleUrl, loadOptions: stylePackLoadOptions) { progress in
            DispatchQueue.main.async {
                channel.onStyleProgress(progress: progress.requiredResourceCount == 0 ? 0 :  Double(Float(progress.completedResourceCount) / Float(progress.requiredResourceCount)))
            }
            
            
        } completion: { result in
            DispatchQueue.main.async {
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case .success(_):
                    print("Success style download")
                    
                case let .failure(error):
                    channel.onError(errorCode: "offlineStyleLoadFailure", errorMessage: error.localizedDescription, errorDetails: nil)
                    downloadError = true
                    
                }
            }
        }
        
        
        // 2. Create an offline region with tiles for the outdoors style
        let outdoorsOptions = TilesetDescriptorOptions(styleURI: region.mapStyleUrl,
                                                       zoomRange: UInt8(region.minZoom)...UInt8(region.maxZoom))
        
        let outdoorsDescriptor = offlineManager.createTilesetDescriptor(for: outdoorsOptions)
        
        // Load the tile region
        let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: region.geometry,
            descriptors: [outdoorsDescriptor],
            metadata: region.metadata,
            acceptExpired: true)!
        
        dispatchGroup.enter()
        let tileRegionDownload = tileStore.loadTileRegion(forId: region.id,
                                                          loadOptions: tileRegionLoadOptions) { (progress) in
            
            DispatchQueue.main.async {
                channel.onTileProgress(progress: progress.requiredResourceCount == 0 ? 0 : Double(Float(progress.completedResourceCount) / Float(progress.requiredResourceCount)))
            }
            
        } completion: { result in
            DispatchQueue.main.async {
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case .success(_):
                    print("Success tile download")
                    
                case let .failure(error):
                    channel.onError(errorCode: "offlineTilesLoadFailure", errorMessage: error.localizedDescription, errorDetails: nil)
                    downloadError = true
                }
            }
        }
        
        // Wait for both downloads before moving to the next state
        dispatchGroup.notify(queue: .main) {
            self.downloads = []
            self.channels = []
            if (downloadError) {
                channel.onError(errorCode: "offlineRegionLoadFailure", errorMessage: "Something went wrong", errorDetails: nil)
            }  else {
                channel.onSuccess()
            }
        }
        downloads = [stylePackDownload, tileRegionDownload]
        channels.append(channel)
    }
    
    func getDownloadedRegionsIds(flutterResult: @escaping FlutterResult) {
        
        guard let tileStore = tileStore else {
            return flutterResult(OfflineResult.failed.rawValue)
        }
        
        tileStore.allTileRegions { result in
            
            switch result {
            case let .success(regions):
                flutterResult(regions.map{(region) -> String in return region.id})
                break
            case let .failure(error) where error is StylePackError:
                flutterResult(OfflineResult.failed.rawValue)
                break
            case .failure:
                flutterResult(OfflineResult.failed.rawValue)
                break
            }
            
        }
    }
    
    func cancelDownloads() {
        downloads.forEach { $0.cancel() }
        channels.forEach {$0.onCancel(withArguments: nil)}
    }
    
    func deleteTilesPackByIds(ids: Array<String>, flutterResult: FlutterResult) {
        guard let tileStore = tileStore else {
            flutterResult(OfflineResult.failed.rawValue)
            return
        }
        for id in ids {
            tileStore.removeTileRegion(forId: id)
        }
        flutterResult(OfflineResult.success.rawValue)
    }
    
    // Remove downloaded region and style pack
    func deleteAllTilesAndStyles(flutterResult: @escaping FlutterResult, accessToken: String) {
        
        if (offlineManager == nil) {
            offlineManager = OfflineManager.init(resourceOptions: ResourceOptions(accessToken:  accessToken))
        }
        
        let dispatchGroup = DispatchGroup()
        
        guard let tileStore = tileStore, let offlineManager = offlineManager else {
            flutterResult(OfflineResult.failed.rawValue)
            return
        }
        
        dispatchGroup.enter()
        
        
        offlineManager.allStylePacks {result in
            DispatchQueue.global().async {
                switch result {
                case let .success(stylePacks):
                    for style in stylePacks {
                        guard let styleUrl = StyleURI(rawValue: style.styleURI) else { return}
                        self.offlineManager?.removeStylePack(for: styleUrl)
                    }
                    dispatchGroup.leave()
                    
                case let .failure(error) where error is StylePackError:
                    flutterResult(OfflineResult.failed.rawValue)
                    dispatchGroup.leave()
                    break
                case .failure:
                    flutterResult(OfflineResult.failed.rawValue)
                    dispatchGroup.leave()
                    break
                }
            }
        }
        
        dispatchGroup.enter()
        
        
        tileStore.allTileRegions { result in
            DispatchQueue.global().async {
                switch result {
                case let .success(tileRegions):
                    for region in tileRegions {
                        tileStore.removeTileRegion(forId: region.id)
                    }
                    tileStore.setOptionForKey(TileStoreOptions.diskQuota, value: 0)
                    dispatchGroup.leave()
                    
                case let .failure(error) where error is TileRegionError:
                    flutterResult(OfflineResult.failed.rawValue)
                    dispatchGroup.leave()
                    break
                case .failure:
                    flutterResult(OfflineResult.failed.rawValue)
                    dispatchGroup.leave()
                    break
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            flutterResult(OfflineResult.success.rawValue)
        }
    }
}

