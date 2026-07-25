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
}
