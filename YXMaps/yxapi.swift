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
        let urlString = "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x=\(x)&y=\(y)&z=\(z)&scale=2.0&lang=ru_RU"
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
    func downloadTile(x: Int, y: Int, z: Int, completion: @escaping (UIImage?) -> Void) {
        let cachePath = yxCache.tile(x: x, y: y, z: z)
        
        if fileManager.fileExists(atPath: cachePath) {
            completion(UIImage(contentsOfFile: cachePath))
        } else {
            NSURLConnection.sendAsynchronousRequest(URLRequest(url: yxURL.tile(x: x, y: y, z: z)), queue: .main) { response, data, error in
                let httpResponse = response as? HTTPURLResponse
                print("REQUESTIN TILE AT \(x), \(y), \(z)")
                if error == nil, let respCode = httpResponse?.statusCode, respCode == 200, let imgData = data, let image = UIImage(data: imgData) {
                    completion(image)
                } else {
                    print("OH NO TILE RIP AAAA!!")
                    print("STATUS CODE IZ \(httpResponse?.statusCode ?? 676767)")
                    completion(nil)
                }
            }
        }
    }
    
    func cacheTile(tile: UIImage, x: Int, y: Int, z: Int) {
        DispatchQueue.global(priority: .low).async {
            if let imgData = tile.pngData() {
                (imgData as NSData).write(to: URL(string: yxCache.tile(x: x, y: y, z: z))!, atomically: true)
            }
        }
    }
}
