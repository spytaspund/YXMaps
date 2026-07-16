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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        let mapSize = CGSize(width: 256 * 16, height: 256 * 16)
        let tiledFrame = CGRect(origin: .zero, size: mapSize)
        
        mapLayer = mapCA(frame: tiledFrame)
        mapLayer.backgroundColor = .lightGray
        scrollView.addSubview(mapLayer)
        scrollView.contentSize = mapSize
        
        let offsetX = (mapSize.width - scrollView.bounds.width) / 2
        let offsetY = (mapSize.height - scrollView.bounds.height) / 2
        
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        print("yeah im loaded bruv")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapLayer
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
        if let tiledLayer = self.layer as? CATiledLayer {
            tiledLayer.tileSize = tileSize
            tiledLayer.levelsOfDetail = 4
            tiledLayer.levelsOfDetailBias = 4
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
            let zoom = Int(round(log2(logicalScale)))
            
            let x = Int(round(rect.origin.x / rect.size.width))
            let y = Int(round(rect.origin.y / rect.size.height))
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
        }
    }
}

