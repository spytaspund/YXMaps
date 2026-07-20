//
//  MapVC.swift
//  YXMaps
//
//  Created by spytaspund on 14.07.2026.
//

import Foundation
import UIKit
import QuartzCore
import CoreText

class mapViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    var mapLayer: mapCA!
    private var isInitialLayoutDone = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        let mapSize = CGSize(width: 256, height: 256)
        let tiledFrame = CGRect(origin: .zero, size: mapSize)
        
        mapLayer = mapCA(frame: tiledFrame)
        mapLayer.backgroundColor = .lightGray
        scrollView.addSubview(mapLayer)
        scrollView.contentSize = mapSize
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = pow(2.0, 17.0)
        scrollView.zoomScale = 1.0
        
        let offsetX = (mapSize.width - scrollView.bounds.width) / 2
        let offsetY = (mapSize.height - scrollView.bounds.height) / 2
        
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        print("yeah im loaded bruv")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calculateMinZoom()
        if !isInitialLayoutDone {
            isInitialLayoutDone = true
            gotoCoords(lat: 38, lon: 38, zoom: 17) // dummy coords; replace with gps data
        }
    }
    
    private func calculateMinZoom() {
        guard scrollView != nil && scrollView.bounds.width > 0 && scrollView.bounds.height > 0 else { return }
        
        let minX = scrollView.bounds.width / 256.0
        let minY = scrollView.bounds.height / 256.0
        let minZoom = max(minX, minY)
        
        scrollView.minimumZoomScale = minZoom
        scrollView.zoomScale = max(minZoom, scrollView.zoomScale)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        mapLayer.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapLayer
    }
    
    func gotoCoords(lat: Double, lon: Double, zoom: Int) {
        let e = 0.0818191908426
        
        let latSin = sin(lat * .pi / 180.0)
        let eLatSin = e * latSin
        
        let p1 = log((1.0 + latSin) / (1.0 - latSin))
        let p2 = e * log((1.0 + eLatSin) / (1.0 - eLatSin))
        
        let x = (lon + 180.0) / 360.0
        let y = 0.5 - (p1 - p2) / (4.0 * .pi)
        
        let targetZoom = pow(2.0, Double(zoom))
        scrollView.zoomScale = CGFloat(targetZoom)
        
        let mapSize = 256.0 * targetZoom
        
        let targetX = (x * mapSize) - Double(scrollView.bounds.width / 2.0)
        let targetY = (y * mapSize) - Double(scrollView.bounds.height / 2.0)
        let maxOffsetX = CGFloat(mapSize) - scrollView.bounds.width
        let maxOffsetY = CGFloat(mapSize) - scrollView.bounds.height
        
        let safeX = max(0, min(CGFloat(targetX), maxOffsetX))
        let safeY = max(0, min(CGFloat(targetY), maxOffsetY))
        scrollView.setContentOffset(CGPoint(x: safeX, y: safeY), animated: false)
    }
}

class mapCA: UIView {
    let tileSize = CGSize(width: 256, height: 256)
    private var screenScale: CGFloat = 1.0
    private var tileCache = [String: UIImage]()
    private let cacheLock = NSLock()
    private var activeDownloads = Set<String>()
    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTiledLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTiledLayer()
    }
    
    private func setupTiledLayer() {
        self.screenScale = UIScreen.main.scale
        self.contentScaleFactor = self.screenScale
        if let tiledLayer = self.layer as? CATiledLayer {
            tiledLayer.tileSize = tileSize
            tiledLayer.contentsScale = self.screenScale
            tiledLayer.levelsOfDetail = 1
            tiledLayer.levelsOfDetailBias = 17
        }
    }
    
    private func cacheKey(x: Int, y: Int, z: Int) -> String {
        return "\(z)_\(x)_\(y)"
    }
    override func draw(_ rect: CGRect) {
        autoreleasepool {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
            let scale = context.ctm.a
            let logicalScale = scale / self.screenScale
            let zoom = Int(round(log2(max(1.0, logicalScale))))
            let maxTiles = 1 << zoom
            
            let x = Int(round(rect.origin.x / rect.size.width))
            let y = Int(round(rect.origin.y / rect.size.height))
            
            guard x >= 0 && x < maxTiles && y >= 0 && y < maxTiles else { return }
            let key = cacheKey(x: x, y: y, z: zoom)
            
            cacheLock.lock()
            let cachedImage = tileCache[key]
            let isDownloading = activeDownloads.contains(key)
            cacheLock.unlock()
            
            context.saveGState()
            
            if let image = cachedImage {
                context.translateBy(x: rect.origin.x, y: rect.origin.y + rect.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                let drawingRect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
                if let cgImage = image.cgImage {
                    context.draw(cgImage, in: drawingRect)
                }
            } else {
                let placeholderColor = UIColor(white: 0.9, alpha: 1.0).cgColor
                context.setFillColor(placeholderColor)
                context.fill(rect)
                    
                context.setStrokeColor(UIColor(white: 0.8, alpha: 1.0).cgColor)
                context.setLineWidth(1.0 / scale)
                context.stroke(rect)
                    
                if !isDownloading {
                    cacheLock.lock()
                    activeDownloads.insert(key)
                    cacheLock.unlock()
                        
                    yxapi.shared.downloadTile(x: x, y: y, z: zoom) { [weak self] downloadedImage in
                        guard let self = self else { return }
                            
                        self.cacheLock.lock()
                        self.tileCache[key] = downloadedImage
                        self.activeDownloads.remove(key)
                        self.cacheLock.unlock()
                            
                        DispatchQueue.main.async {
                            self.setNeedsDisplay(rect)
                        }
                    }
                }
            }
            context.restoreGState()
        }
    }
}

