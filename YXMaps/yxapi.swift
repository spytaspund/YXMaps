//
//  yxapi.swift
//  YXMaps
//
//  Created by spytaspund on 16.07.2026.
//

import Foundation
import UIKit

struct yxURL {
    static func tile(x: Int, y: Int, z: Int) -> URL {
        let urlString = "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x=\(x)&y=\(y)&z=\(z)&scale=1.0&lang=ru_RU&scale=2.0"
        return URL(string: urlString)!
    }
    
    static func satTile(x: Int, y: Int, z: Int) -> URL {
        let urlString = "https://sat03.maps.yandex.net/tiles?l=sat&x=\(x)&y=\(y)&z=\(z)&lang=ru_RU"
        return URL(string: urlString)!
    }
    
    static func overlayTile(x: Int, y: Int, z: Int) -> URL {
        let urlString = "https://core-renderer-tiles.maps.yandex.net/tiles?l=skl&x=\(x)&y=\(y)&z=\(z)&scale=1&lang=ru_RU"
        return URL(string: urlString)!
    }
}

struct yxCache {
    static func tile(x: Int, y: Int, z: Int) -> String {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return (cacheDir as NSString).appendingPathComponent("yxTiles/\(z)/\(x)/\(y).png")
    }
}

class yxapi {
    static let shared = yxapi()
    private var fileManager = FileManager.default
    private var queue = DispatchQueue(label: "com.yxmaps.tileQueue", attributes: .concurrent)
    private var activeRequests = Set<String>()
    
    func downloadTile(x: Int, y: Int, z: Int, completion: @escaping (CGImage) -> Void) -> CGImage? {
        let cachePath = yxCache.tile(x: x, y: y, z: z)
        
        // checking disk cache
        if fileManager.fileExists(atPath: cachePath), let image = UIImage(contentsOfFile: cachePath), let cgImage = image.cgImage {
            return cgImage
        }
        
        // queue thingies; needed becuase otherwise tiles will be redownloaded every N ms.
        let tileID = "\(z)_\(x)_\(y)"
        var shouldDownload = false
        queue.sync(flags: .barrier) {
            if !activeRequests.contains(tileID) {
                activeRequests.insert(tileID)
                shouldDownload = true
            }
        }
        
        guard shouldDownload else { return nil }
        
        let url = yxURL.tile(x: x, y: y, z: z)
        let request = URLRequest(url: url)
        print("REQUESTIN URL: \(url.absoluteString)")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: .main) { [weak self] response, data, error in
            self?.queue.async(flags: .barrier) {
                self?.activeRequests.remove(tileID)
            }
            let httpResponse = response as? HTTPURLResponse
            print("COORDZ \(z), \(x), \(y)")
            print("STATUS CODE IZ \(httpResponse?.statusCode ?? 676767)")
            if error == nil, let respCode = httpResponse?.statusCode, respCode == 200, let imgData = data, let image = UIImage(data: imgData), let cgImage = image.cgImage {
                self?.cacheTile(data: imgData, x: x, y: y, z: z)
                completion(cgImage)
            } else {
                print("OH NO TILE RIP AAAA!!")
            }
        }
        return nil
    }
    
    func cacheTile(data: Data, x: Int, y: Int, z: Int) {
        DispatchQueue.global(priority: .background).async {
            let cachePath = yxCache.tile(x: x, y: y, z: z)
            let nsCachePath = cachePath as NSString
            let url = URL(fileURLWithPath: cachePath)
            let directoryPath = nsCachePath.deletingLastPathComponent
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                try data.write(to: url, options: .atomic)
            } catch {
                print("OH NO TILE IS NOT VALID SHIT SHIT AAAA!!")
                print("ERROR DISCRIPTZ:: \(error.localizedDescription)")
            }
        }
    }
}
