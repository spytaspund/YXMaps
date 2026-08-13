//
//  yxapi.swift
//  YXMaps
//
//  Created by spytaspund on 16.07.2026.
//

import Foundation
import UIKit

struct yxURL {
    static func tile(x: Int, y: Int, z: Int, scale: CGFloat, isDark: Bool) -> URL {
        let urlString = "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&x=\(x)&y=\(y)&z=\(z)&scale=\(scale)&theme=\(isDark ? "dark" : "light")&lang=ru_RU"
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
    
    static func geoSuggest(query: String, lat: Double, lon: Double) -> URL {
        let urlString = "https://suggest-maps.yandex.ru/suggest-geo?part=\(query.encodeForJS())&ll=\(lon),\(lat)&outformat=json&v=9&lang=ru_RU"
        print("DEBUG SUGGEST URL: \(urlString)")
        return URL(string: urlString)!
    }
}

struct yxCache {
    static func tile(x: Int, y: Int, z: Int, isDark: Bool) -> String {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return (cacheDir as NSString).appendingPathComponent("yxTiles/\(isDark ? "dark" : "light")/\(z)/\(x)/\(y).png")
    }
    
    static func satTile(x: Int, y: Int, z: Int) -> String {
        let cacheDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return (cacheDir as NSString).appendingPathComponent("yxTiles/satellite/\(z)/\(x)/\(y).png")
    }
}

struct yxData {
    struct suggestData: Decodable { let results: [suggestResult] }
    
    struct suggestResult: Decodable {
        let type: String
        let title: suggestTitle
        let subtitle: suggestTitle
        let distance: suggestDistance
        let tags: [String]
    }
    
    struct suggestTitle: Decodable { let text: String }
    struct suggestDistance: Decodable {
        let value: Float
        let text: String
    }
}

class yxapi {
    static let shared = yxapi()
    private var fileManager = FileManager.default
    private var ramCache = NSCache<NSString, UIImage>()
    private var tileQueue = DispatchQueue(label: "com.yxmaps.tileQueue", attributes: .concurrent)
    private var tileRequests = Set<String>()
    
    private var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:153.0) Gecko/20100101 Firefox/153.0"
    private var csrfToken: String?
    private var sessionID: String?
    private var bootstrapped = false
    
    private func djb2Hash(_ string: String) -> String { // needed to sign URLs (?s param)
        var hash: UInt32 = 5381
        for scalar in string.unicodeScalars {
            hash = ((hash &* 33) ^ scalar.value)
        }
        return String(hash)
    }
    
    private func regExtract(from text: String, regex pattern: String) -> String? { // needed to find csrf and sessionid in html
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range), let valueRange = Range(match.range(at: 1), in: text) {
            return String(text[valueRange])
        }
        return nil
    }
    
    func bootstrap(completion: @escaping (Bool) -> Void) {
        print("IM BOOTSTRAPPIN SO HARD OOOH")
        
        if csrfToken != nil, sessionID != nil {
            bootstrapped = true
            completion(true)
            return
        }
        
        guard let url = URL(string: "https://yandex.ru/maps") else {
            bootstrapped = false
            completion(false)
            return
        }
        
        let request = NSMutableURLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.httpShouldHandleCookies = true
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: .main) { [weak self] response, data, error in
            guard let self = self else { return }
            if error == nil, let data = data, let html = String(data: data, encoding: .utf8) {
                self.csrfToken = self.regExtract(from: html, regex: #"\"csrfToken\"\s*:\s*\"([^\"]+)\""#)
                self.sessionID = self.regExtract(from: html, regex: #"\"sessionId\"\s*:\s*\"([^\"]+)\""#)
                print("CSRF TOKIN: \(self.csrfToken ?? "nil"), SESSIN ID IZ \(self.sessionID ?? "nil")")
                let success = self.csrfToken != nil && self.sessionID != nil
                self.bootstrapped = success
                completion(success)
            } else {
                self.bootstrapped = false
                completion(false)
            }
        }
    }
    
    func search(query: String, ll: String, completion: @escaping (String?) -> Void) {
        if !bootstrapped || csrfToken == nil || sessionID == nil {
            bootstrap { [weak self] success in
                if success {
                    self?.searchRequest(query: query, ll: ll, completion: completion)
                } else {
                    completion(nil)
                }
            }
        } else {
            searchRequest(query: query, ll: ll, completion: completion)
        }
    }
    
    func route(start: (Double, Double), end: (Double, Double), completion: @escaping (String?) -> Void) {
        if !bootstrapped || csrfToken == nil || sessionID == nil {
            bootstrap { [weak self] success in
                if success {
                    self?.routeRequest(start: start, end: end, completion: completion)
                } else {
                    completion(nil)
                }
            }
        } else {
            routeRequest(start: start, end: end, completion: completion)
        }
    }
        
    private func searchRequest(query: String, ll: String, completion: @escaping (String?) -> Void) {
        guard let csrf = self.csrfToken, let id = self.sessionID else {
            completion(nil)
            return
        }
        
        let params: [String: String] = [
            "add_type": "direct",
            "ajax": "1",
            "csrfToken": csrf,
            "direct_page_id": "670942",
            "lang": "ru_RU",
            "ll": ll,
            "mode": "uri",
            "origin": "maps-form",
            "results": "25",
            "sessionId": id,
            "snippets": "masstransit/2.x,panoramas/1.x,businessrating/1.x,photos/2.x",
            "text": query,
            "z": "9"
        ]
        
        let requestStr = params.keys.sorted().map { key in
            "\(key.encodeForJS())=\(params[key]!.encodeForJS())"
        }.joined(separator: "&")
        
        let s = self.djb2Hash(requestStr)
        guard let url = URL(string: "https://yandex.ru/maps/api/search?\(requestStr)&s=\(s)") else {
            completion(nil)
            return
        }
        
        print(url.absoluteString)
        let request = NSMutableURLRequest(url: url)
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://yandex.ru", forHTTPHeaderField: "Origin")
        request.setValue("https://yandex.ru/maps/", forHTTPHeaderField: "Referer")
        request.httpShouldHandleCookies = true
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: .main) { response, data, error in
            if let data = data, error == nil, let json = String(data: data, encoding: .utf8) {
                completion(json)
            } else {
                completion(nil)
            }
        }
    }
    
    private func routeRequest(start: (Double, Double), end: (Double, Double), completion: @escaping (String?) -> Void) {
        guard let csrf = self.csrfToken, let id = self.sessionID else {
            completion(nil)
            return
        }
        
        let params: [String: String] = [
            "ajax": "1",
            "csrfToken": csrf,
            "isHDRoutesExperiment": "true",
            "isIntercityRoute": "true",
            "lang": "ru",
            "locale": "ru_RU",
            "mode": "best",
            "rll": "\(start.0),\(start.1)~\(end.0),\(end.1)",
            "sessionId": id,
            "type": "auto"
        ]
        
        let requestStr = params.keys.sorted().map { key in
            "\(key.encodeForJS())=\(params[key]!.encodeForJS())"
        }.joined(separator: "&")
        
        let s = self.djb2Hash(requestStr)
        guard let url = URL(string: "https://yandex.ru/maps/api/router/buildRoute?\(requestStr)&s=\(s)") else {
            completion(nil)
            return
        }
        
        print(url.absoluteString)
        let request = NSMutableURLRequest(url: url)
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://yandex.ru", forHTTPHeaderField: "Origin")
        request.setValue("https://yandex.ru/maps/", forHTTPHeaderField: "Referer")
        request.httpShouldHandleCookies = true
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: .main) { response, data, error in
            if let data = data, error == nil, let json = String(data: data, encoding: .utf8) {
                completion(json)
            } else {
                completion(nil)
            }
        }
    }
    
    func suggest(query: String, lat: Double, lon: Double, completion: @escaping ([yxData.suggestResult]?) -> Void) {
        let url = yxURL.geoSuggest(query: query, lat: lat, lon: lon)
        let request = URLRequest(url: url)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: .main) { response, data, error in
            if error == nil, let rawJSON = data {
                print("DEBUGI JSONCHIK!: \(String(data: rawJSON, encoding: .utf8) ?? "blya ya hz chet")")
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let results = try decoder.decode(yxData.suggestData.self, from: rawJSON)
                    let suggestArray = results.results
                    completion(suggestArray)
                } catch {
                    print("JSON DECODE ERROR!! \(error)")
                }
            } else {
                print("SUGGEST NET ERRIR!! \(String(describing: error))")
            }
        }
    }
    
    // MARK: tiles
    
    func downloadTile(x: Int, y: Int, z: Int, scale: CGFloat, isDark: Bool, isSat: Bool, completion: @escaping (CGImage) -> Void) -> CGImage? {
        let tileID = "\(isSat ? "s" : (isDark ? "d" : "l"))_\(z)_\(x)_\(y)"
        
        if let ramTile = ramCache.object(forKey: tileID as NSString), let cgTile = ramTile.cgImage { return cgTile }
        
        var cachePath: String {
            if isSat { return yxCache.satTile(x: x, y: y, z: z)}
            else { return yxCache.tile(x: x, y: y, z: z, isDark: isDark)}
        }
        
        // checking disk cache
        if fileManager.fileExists(atPath: cachePath), let image = UIImage(contentsOfFile: cachePath), let cgImage = image.cgImage {
            ramCache.setObject(image, forKey: tileID as NSString)
            return cgImage
        }
        
        // queue thingies; needed becuase otherwise tiles will be redownloaded every N ms.
        var isNewRequest = false
        tileQueue.sync(flags: .barrier) {
            isNewRequest = tileRequests.insert(tileID).inserted
        }
        guard isNewRequest else { return nil }
        
        var url: URL {
            if isSat { return yxURL.satTile(x: x, y: y, z: z) }
            else { return yxURL.tile(x: x, y: y, z: z, scale: scale, isDark: isDark) }
        }
        let request = URLRequest(url: url)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { [weak self] response, data, error in
            let httpResponse = response as? HTTPURLResponse
            if error == nil, let respCode = httpResponse?.statusCode, respCode == 200, let imgData = data, let image = UIImage(data: imgData), let cgImage = image.cgImage {
                self?.ramCache.setObject(image, forKey: tileID as NSString)
                self?.cacheTile(data: imgData, x: x, y: y, z: z, isDark: isDark, isSat: isSat)
                self?.tileQueue.async(flags: .barrier) {
                    self?.tileRequests.remove(tileID)
                }
                DispatchQueue.main.async {
                    completion(cgImage)
                }
            } else {
                self?.tileQueue.async(flags: .barrier) {
                    self?.tileRequests.remove(tileID)
                }
                print("OH NO TILE RIP AAAA!!")
            }
        }
        return nil
    }
    
    func cacheTile(data: Data, x: Int, y: Int, z: Int, isDark: Bool, isSat: Bool) {
        DispatchQueue.global(priority: .background).async {
            var cachePath: String {
                if isSat { return yxCache.satTile(x: x, y: y, z: z)}
                else { return yxCache.tile(x: x, y: y, z: z, isDark: isDark)}
            }
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
    
    func resetTileRequests() {
        tileQueue.async(flags: .barrier) {
            self.tileRequests.removeAll()
        }
    }
}

extension String {
    func encodeForJS() -> String {
        let unreserved = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~'*()")
        return self.utf8.map { byte -> String in
            let scalar = UnicodeScalar(byte)
            if unreserved.contains(scalar) {
                return String(Character(scalar))
            } else {
                return String(format: "%%%02X", byte)
            }
        }.joined()
    }
    
    func toIconName(isDark: Bool) -> String {
        let slug = self.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        
        let suffix = isDark ? "-dark" : "-light"
        return "\(slug)\(suffix)"
    }
}
