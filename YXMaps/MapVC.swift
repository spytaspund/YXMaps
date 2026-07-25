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
    private var gpsMgr = swiftGPS()
    var mapLayer: mapCA!
    
    private var locationDotView: UIView?
    private var isInitialLayoutDone = false
    let mapSize = CGSize(width: pow(2.0, 17.0) * 256, height: pow(2.0, 17.0) * 256)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        let tiledFrame = CGRect(origin: .zero, size: mapSize)
        
        mapLayer = mapCA(frame: tiledFrame)
        mapLayer.backgroundColor = .lightGray
        scrollView.addSubview(mapLayer)
        scrollView.contentSize = mapSize
        
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0 / pow(2.0, 17.0)
        scrollView.zoomScale = 1.0
        
        // fallback - 0" 0" coords (null island)
        let offsetX = (mapSize.width - scrollView.bounds.width) / 2
        let offsetY = (mapSize.height - scrollView.bounds.height) / 2
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        
        gpsMgr.onGPSUpdate = { [weak self] lat, lon in
            guard let self = self else { return }
            let coords = self.tranformCoordinate(lat, lon, withZoom: 17)
            let pixelX = CGFloat(coords.x * 256)
            let pixelY = CGFloat(coords.y * 256)
            let dotPos = CGPoint(x: pixelX, y: pixelY)
            
            if self.locationDotView == nil {
                let size: CGFloat = 20.0
                let dot = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
                dot.backgroundColor = UIColor(red: 1.0, green: 0.27, blue: 0.2, alpha: 1.0)
                dot.layer.cornerRadius = size / 2.0
                dot.layer.borderColor = UIColor.white.cgColor
                dot.layer.borderWidth = 4
                
                dot.layer.shadowColor = UIColor.black.cgColor
                dot.layer.shadowOffset = CGSize(width: 0, height: 2)
                dot.layer.shadowOpacity = 0.3
                dot.layer.shadowRadius = 2.0
                
                self.mapLayer.addSubview(dot)
                self.locationDotView = dot
            }
            self.locationDotView?.center = dotPos
            self.updateDotScale()
            
            if !self.isInitialLayoutDone {
                self.isInitialLayoutDone = true
                self.gotoCoords(lat: lat, lon: lon)
            }
        }
        gpsMgr.startTracking()
        
        print("yeah im loaded bruv")
    }
    
    // prevents going out of bounds
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculateMinZoom()
    }
    
    private func calculateMinZoom() {
        guard scrollView != nil && scrollView.bounds.width > 0 && scrollView.bounds.height > 0 else { return }
        
        let minX = scrollView.bounds.width / mapSize.width
        let minY = scrollView.bounds.height / mapSize.height
        let minZoom = max(minX, minY)
        
        scrollView.minimumZoomScale = minZoom
        if scrollView.zoomScale < minZoom {
            scrollView.zoomScale = minZoom
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        mapLayer.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        updateDotScale()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapLayer
    }
    
    // zooming the dot with the map
    private func updateDotScale() {
        guard let dot = locationDotView else { return }
        let currentZoom = scrollView.zoomScale
        dot.transform = CGAffineTransform(scaleX: 1.0 / currentZoom, y: 1.0 / currentZoom)
    }
    
    // c++ func found on yx forums translated to swift
    func tranformCoordinate(_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let latRad = latitude * Double.pi / 180.0
        let lonRad = longitude * Double.pi / 180.0
        
        let a: Double = 6378137
        let k: Double = 0.0818191908426
        let zoomPow = pow(2.0, Double(23 - zoom))
        
        let pixX = round((20037508.342789 + a * lonRad) * 53.5865938 / zoomPow)
        let tileX = Int(pixX) / 256
        
        let sinLat = sin(latRad)
        let asinPart = asin(k * sinLat)
        
        let tanNum = tan(Double.pi / 4.0 + latRad / 2.0)
        let tanDen = tan(Double.pi / 4.0 + asinPart / 2.0)
        
        let z1 = tanNum / pow(tanDen, k)
        
        let pixY = round((20037508.342789 - a * log(z1)) * 53.5865938 / zoomPow)
        let tileY = Int(pixY) / 256
        
        return (tileX, tileY)
    }
    
    func gotoCoords(lat: Double, lon: Double) {
        print("FOUND IT!! Lat: \(lat), Lon: \(lon)")
        let coords = self.tranformCoordinate(lat, lon, withZoom: 17)
        let pixelX = CGFloat(coords.x * 256)
        let pixelY = CGFloat(coords.y * 256)
        let targetOffset = CGPoint(
            x: pixelX - (scrollView.bounds.width / 2),
            y: pixelY - (scrollView.bounds.height / 2)
        )
        scrollView.zoomScale = 1.0
        scrollView.setContentOffset(targetOffset, animated: false)
    }
}

class mapCA: UIView {
    let tileSize = CGSize(width: 512, height: 512) // this is awkard; needs to work with 256x256, but it does some weird shit with that size, so I need to use scale=2.0 + size=512x512
    let lods = 18
    let lodBias = 0
    
    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTiledLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTiledLayer()
    }
    
    private func setupTiledLayer() {
        let lr = self.layer as! CATiledLayer
        lr.tileSize = tileSize
        lr.levelsOfDetail = lods
        lr.levelsOfDetailBias = lodBias
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        let scale = ctx.ctm.a / layer.contentsScale // stupid retina displays
        let rect = ctx.boundingBoxOfClipPath
        
        let maxZoom = 17
        let z = max(0, min(maxZoom, maxZoom + Int(round(log2(scale)))))
        
        let tileSizeAtCurrentScale = 256.0 / scale
        let x = Int(rect.origin.x / tileSizeAtCurrentScale)
        let y = Int(rect.origin.y / tileSizeAtCurrentScale)
        
        let cachedTile = yxapi.shared.downloadTile(x: x, y: y, z: z) { [weak layer] downloadedTile in
            // Runs if tile is NOT cached and downloaded from server
            layer?.setNeedsDisplay(rect)
        }
        
        guard let tile = cachedTile else {
            // nil received - either tile is downloading, or there's API error.
            ctx.setFillColor(UIColor(white: 0.88, alpha: 1.0).cgColor)
            ctx.fill(rect)
            return
        }
        
        ctx.saveGState()
        ctx.translateBy(x: rect.origin.x, y: rect.origin.y + rect.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        let localRect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        ctx.draw(tile, in: localRect)
        
        ctx.restoreGState()
    }
}
