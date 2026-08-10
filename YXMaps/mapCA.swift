//
//  mapCA.swift
//  YXMaps
//
//  Created by spytaspund on 31.07.2026.
//

import Foundation
import UIKit

class mapCA: UIView {
    var tileSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: 256 * scale, height: 256 * scale)
    }
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
        
        let x = Int(rect.origin.x / rect.width)
        let y = Int(rect.origin.y / rect.height)
        
        let isDark = theme.shared.selectedTheme == .dark
        let isSat = UserDefaults.standard.integer(forKey: settingKeys.mapType) == 1 // 0 - scheme, 1 - satellite
        let cachedTile = yxapi.shared.downloadTile(x: x, y: y, z: z, scale: layer.contentsScale, isDark: isDark, isSat: isSat) { [weak layer] downloadedTile in
            // Runs if tile is NOT cached and downloaded from server
            layer?.setNeedsDisplay(rect)
        }
        
        guard let tile = cachedTile else {
            // nil received - either tile is downloading, or there's API error.
            ctx.setFillColor(palette.secondaryBackground.cgColor)
            ctx.fill(rect)
            ctx.setFillColor(palette.secondaryLabel.cgColor)
            
            let step: CGFloat = 32.0
                
            var x = rect.minX
            while x < rect.maxX {
                var y = rect.minY
                while y < rect.maxY {
                    ctx.fill(CGRect(x: x, y: y, width: 2, height: 2))
                    y += step
                }
                x += step
            }
            return
        }
        
        ctx.saveGState()
        ctx.translateBy(x: rect.origin.x, y: rect.origin.y + rect.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        
        let localRect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        ctx.draw(tile, in: localRect)
        
        ctx.restoreGState()
    }
    
    func reloadMap() {
        if let tiledlayer = self.layer as? CATiledLayer {
            let currentLods = tiledlayer.levelsOfDetail
            tiledlayer.levelsOfDetail = max(1, currentLods - 1)
            DispatchQueue.main.async {
                tiledlayer.levelsOfDetail = currentLods
                self.setNeedsDisplay()
            }
        }
    }
}
