//
//  yxapi.swift
//  YXMaps
//
//  Created by spytaspund on 16.07.2026.
//

import Foundation
import UIKit

struct yxURL {
    static func tile(x: Int, y: Int, z: Int, apiKey: String) -> URL {
        let urlString = "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x=\(x)&y=\(y)&z=\(z)&scale=1&lang=ru_RU&apiKey=\(apiKey)&l=map"
        print("givin url: \(urlString)")
        return URL(string: urlString)!
    }
}
class yxapi {
    static let shared = yxapi()
    let apiKey: String = "" // very bad practice
    
    func downloadTile(x: Int, y: Int, z: Int, completion: @escaping (UIImage?) -> Void) {
        NSURLConnection.sendAsynchronousRequest(URLRequest(url: yxURL.tile(x: x, y: y, z: z, apiKey: self.apiKey)), queue: .main) { response, data, error in
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
