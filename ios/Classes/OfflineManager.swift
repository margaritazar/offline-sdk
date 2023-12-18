import Foundation
import UIKit
import MapboxMaps


final class OfflineManagerInterface {
    
    private var tileStore: TileStore? = TileStore.default
    static let sharedInstance = OfflineManagerInterface()
    
    private lazy var mapInitOptions: MapInitOptions = {
        MapInitOptions(cameraOptions: CameraOptions(center: tokyoCoord, zoom: tokyoZoom),
                       styleURI: .outdoors)
    }()
    
    private lazy var offlineManager: OfflineManager = {
        return OfflineManager.init(resourceOptions: ResourceOptions(accessToken: ""))
    }()
    private var downloads: [Cancelable] = []
    
    // TODO: delete, used only for tests now
    private let tokyoCoord = CLLocationCoordinate2D(latitude: 35.682027, longitude: 139.769305)
    private let tokyoZoom: CGFloat = 12
    private let tileRegionId = "myTileRegion"
    
    private enum State {
        case unknown
        case initial
        case downloading
        case downloaded
        case mapViewDisplayed
        case finished
    }
    
    
    // MARK: - Actions
    
    func downloadTileRegions() {
        guard let tileStore = tileStore else {
            preconditionFailure()
        }
        
        precondition(downloads.isEmpty)
        
        let dispatchGroup = DispatchGroup()
        var downloadError = false
        
        // - - - - - - - -
        
        // 1. Create style package with loadStylePack() call.
        let stylePackLoadOptions = StylePackLoadOptions(glyphsRasterizationMode: .ideographsRasterizedLocally,
                                                        metadata: ["tag": "my-outdoors-style-pack"])!
        
        dispatchGroup.enter()
        let stylePackDownload = offlineManager.loadStylePack(for: .outdoors, loadOptions: stylePackLoadOptions) { [weak self] progress in
            // These closures do not get called from the main thread. In this case
            // we're updating the UI, so it's important to dispatch to the main
            // queue.
            
            
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case let .success(stylePack):
                    print("Success style download")
                    
                case let .failure(error):
                    downloadError = true
                }
            }
        }
        
        // - - - - - - - -
        
        // 2. Create an offline region with tiles for the outdoors style
        let outdoorsOptions = TilesetDescriptorOptions(styleURI: .outdoors,
                                                       zoomRange: 0...16)
        
        let outdoorsDescriptor = offlineManager.createTilesetDescriptor(for: outdoorsOptions)
        
        // Load the tile region
        let tileRegionLoadOptions = TileRegionLoadOptions(
            geometry: .point(Point(tokyoCoord)),
            descriptors: [outdoorsDescriptor],
            metadata: ["tag": "my-outdoors-tile-region"],
            acceptExpired: true)!
        
        dispatchGroup.enter()
        let tileRegionDownload = tileStore.loadTileRegion(forId: tileRegionId,
                                                          loadOptions: tileRegionLoadOptions) { [weak self] (progress) in
            
            DispatchQueue.main.async {
                print("[\("Example")] \(progress)")
            }
        } completion: { [weak self] result in
            DispatchQueue.main.async {
                defer {
                    dispatchGroup.leave()
                }
                
                switch result {
                case let .success(tileRegion):
                    print("Success tile download")
                    
                case let .failure(error):
                    downloadError = true
                }
            }
        }
        
        // Wait for both downloads before moving to the next state
        dispatchGroup.notify(queue: .main) {
            self.downloads = []
        }
        
        // TODO: implement stream
        downloads = [stylePackDownload, tileRegionDownload]
    }
    
    // TODO: implement it
    private func cancelDownloads() {
        // Canceling will trigger `.canceled` errors that will then change state
        downloads.forEach { $0.cancel() }
    }
    
    // TODO: implement it
    // Remove downloaded region and style pack
    private func removeTileRegionAndStylePack() {
        // Remove the tile region with the tile region ID.
        // Note this will not remove the downloaded tile packs, instead, it will
        // just mark the tileset as not a part of a tile region. The tiles still
        // exists in a predictive cache in the TileStore.
        tileStore?.removeTileRegion(forId: tileRegionId)
        
        // Set the disk quota to zero, so that tile regions are fully evicted
        // when removed.
        // This removes the tiles from the predictive cache.
        tileStore?.setOptionForKey(TileStoreOptions.diskQuota, value: 0)
        
        // Remove the style pack with the style uri.
        // Note this will not remove the downloaded style pack, instead, it will
        // just mark the resources as not a part of the existing style pack. The
        // resources still exists in the disk cache.
        offlineManager.removeStylePack(for: .outdoors)
    }
}
