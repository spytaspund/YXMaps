//
//  gps.swift
//  YXMaps
//
//  Created by spytaspund on 25.07.2026.
//

import Foundation

class swiftGPS: NSObject, gpsDelegate {
    private let manager = gps()
    
    public var latitude: Double?
    public var longitude: Double?
    public var error: Error?
    
    var onGPSUpdate: ((Double, Double) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func startTracking() {
        manager.startTracking()
    }

    func stopTracking() {
        manager.stopTracking()
    }
    
    func didUpdateLocationLat(_ lat: Double, lon: Double) {
        self.latitude = lat
        self.longitude = lon
        onGPSUpdate?(lat, lon)
    }

    func didFailWithError(_ error: Error) {
        self.error = error
        print("OH NOO GPS DIED!! ERROR IS: \(error.localizedDescription)")
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
}
