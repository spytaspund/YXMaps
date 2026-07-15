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
    
    override func draw(_ rect: CGRect) {
        autoreleasepool {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
            let scale = context.ctm.a
            let logicalScale = scale / self.screenScale
            let zoom = Int(round(log2(logicalScale)))
            
            let zoomColors: [UIColor] = [
                UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0),
                UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0),
                UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0),
                UIColor(red: 1.0, green: 0.9, blue: 1.0, alpha: 1.0)
            ]
            
            let colorIndex = abs(zoom) % zoomColors.count
            let tileBGColor = zoomColors[colorIndex].cgColor
            
            context.saveGState()
            context.setFillColor(tileBGColor)
            context.fill(rect)
            
            let borderColor = UIColor.red.cgColor
            context.setStrokeColor(borderColor)
            context.setLineWidth(2.0 / scale)
            context.stroke(rect)
            
            let crossColor = UIColor(white: 0.3, alpha: 0.5).cgColor
            context.setStrokeColor(crossColor)
            context.setLineWidth(1.0 / scale)
            
            context.move(to: CGPoint(x: rect.minX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            
            context.strokePath()
            context.restoreGState()
        }
    }
}
