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
    
    struct ratingData: Decodable {
        let ratingCount: Int
        let ratingValue: Double
        let reviewCount: Int
    }
    
    struct workingStatus: Decodable {
        let isOpenNow: Bool
        let text: String
        let shortText: String
    }
    
    struct searchResult: Decodable {
        let type: String
        let title: String
        let description: String
        let address: String
        let ratingData: ratingData?
        let currentWorkingStatus: workingStatus?
    }
    
    struct rawSearch: Decodable { let data: searchData }
    struct searchData: Decodable {
        let items: [searchResult]
    }
}

class yxapi {
    static let shared = yxapi()
    private var fileManager = FileManager.default
    private var ramCache = NSCache<NSString, UIImage>()
    private let tileOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.yxmaps.tileQueue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    private let networkQueue = OperationQueue()
    private let tileAccessQueue = DispatchQueue(label: "com.yxmaps.tileAccessQueue")
    private var tileRequests = Set<String>()
        
    private var userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:153.0) Gecko/20100101 Firefox/153.0"
    private var csrfToken: String?
    private var sessionID: String?
    private var bootstrapped = false
    
    init() {
        ramCache.countLimit = 64
    }
    
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
    
    func search(query: String, ll: String, completion: @escaping ([yxData.searchResult]?) -> Void) {
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
        
    private func searchRequest(query: String, ll: String, completion: @escaping ([yxData.searchResult]?) -> Void) {
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
            if let data = data, error == nil {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decoded = try decoder.decode(yxData.rawSearch.self, from: data)
                    completion(decoded.data.items)
                } catch {
                    print("SEARCH DECODE ERROR!! \(error)")
                    completion(nil)
                }
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
        let tileID = "\(z)_\(x)_\(y)"
        TileLogger.shared.log("REQ \(tileID)")
        
        if let ramTile = ramCache.object(forKey: tileID as NSString), let cgTile = ramTile.cgImage {
            TileLogger.shared.log("HIT RAM \(tileID)")
            return cgTile
        }
        
        let cachePath = isSat ? yxCache.satTile(x: x, y: y, z: z) : yxCache.tile(x: x, y: y, z: z, isDark: isDark)
        
        if fileManager.fileExists(atPath: cachePath),
           let image = UIImage(contentsOfFile: cachePath),
           let cgImage = image.cgImage {
            TileLogger.shared.log("HIT DISK \(tileID)")
            ramCache.setObject(image, forKey: tileID as NSString)
            DispatchQueue.main.async {
                completion(cgImage)
            }
            return nil
        }
        
        var isNewRequest = false
        tileAccessQueue.sync {
            if !tileRequests.contains(tileID) {
                tileRequests.insert(tileID)
                isNewRequest = true
            }
        }
        
        guard isNewRequest else {
            TileLogger.shared.log("SKIP DUP \(tileID)")
            return nil
        }
        
        let url = isSat ? yxURL.satTile(x: x, y: y, z: z) : yxURL.tile(x: x, y: y, z: z, scale: scale, isDark: isDark)
        var request = URLRequest(url: url)
        request.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
        
        TileLogger.shared.log("NET START \(tileID)")
        
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) { [weak self] response, data, error in
            guard let self = self else { return }
            
            self.tileAccessQueue.async {
                self.tileRequests.remove(tileID)
            }
            
            if let error = error {
                TileLogger.shared.log("NET ERR \(tileID): \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                TileLogger.shared.log("NET ERR \(tileID): Bad Response")
                return
            }
            
            if httpResponse.statusCode != 200 {
                TileLogger.shared.log("NET HTTP \(httpResponse.statusCode) \(tileID)")
                return
            }
            
            guard let imgData = data, let image = UIImage(data: imgData), let cgImage = image.cgImage else {
                TileLogger.shared.log("NET BAD DATA \(tileID)")
                return
            }
            
            TileLogger.shared.log("NET OK \(tileID) (\(imgData.count)b)")
            
            self.ramCache.setObject(image, forKey: tileID as NSString)
            self.cacheTile(data: imgData, path: cachePath)
            
            completion(cgImage)
        }
        
        return nil
    }
    
    private func cacheTile(data: Data, path: String) {
        DispatchQueue.global(priority: .background).async {
            let url = URL(fileURLWithPath: path)
            let directoryPath = (path as NSString).deletingLastPathComponent
            let fm = FileManager.default
            do {
                try fm.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                try data.write(to: url, options: .atomic)
            } catch {
                print("CACHE WRITE ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    func resetTileRequests() {
        tileAccessQueue.async {
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

class TileLogger {
    static let shared = TileLogger()
    
    weak var debugLabel: UILabel?
    
    private let queue = DispatchQueue(label: "com.yxmaps.loggerQueue")
    private var logLines: [String] = []
    private let maxLines = 12
    
    func log(_ message: String) {
        let timestamp = String(format: "%.2f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
        let threadInfo = Thread.isMainThread ? "MAIN" : "BG-\(String(format: "%04x", pthread_mach_thread_np(pthread_self())))"
        let fullMessage = "[\(timestamp)][\(threadInfo)] \(message)"
        
        NSLog("%@", fullMessage)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logLines.append(fullMessage)
            if self.logLines.count > self.maxLines {
                self.logLines.removeFirst(self.logLines.count - self.maxLines)
            }
            let textToDisplay = self.logLines.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.debugLabel?.text = textToDisplay
            }
        }
    }
}
