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
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var locationBtn: UIButton!
    
    @IBOutlet weak var searchBarHeight: NSLayoutConstraint!
    @IBOutlet weak var searchBarBottomPhone: NSLayoutConstraint!
    
    private var gpsMgr = swiftGPS()
    var mapLayer: mapCA!
    
    private var locationDotView: UIView?
    private var isInitialLayoutDone = false
    private var currentLat: Double?
    private var currentLon: Double?
    
    private var suggestVC: suggestVC? {
        return children.first(where: { $0 is suggestVC }) as? suggestVC
    }
    private var searchResult: yxData.searchResult?
    
    let mapSize = CGSize(width: pow(2.0, 17.0) * 256, height: pow(2.0, 17.0) * 256)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: Notification.Name("themeChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mapTypeChanged),
            name: Notification.Name("mapTypeChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true // ^ somehow doesn't work without it
        
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
            
            self.currentLat = lat
            self.currentLon = lon
            self.updateDotLocation(lat: lat, lon: lon)
            
            if !self.isInitialLayoutDone {
                self.isInitialLayoutDone = true
                self.gotoGPS()
            }
        }
        gpsMgr.startTracking()
        
        yxapi.shared.search(query: "Третьяковская галерея", ll: "34.459061, 51.187538") { json in
            if let jsonchik = json {
                print("YEA GUD!!")
                print("RESULT: \(jsonchik.description)")
                self.searchResult = jsonchik
                self.showResultVC()
            } else {
                print("FUCK U!!!")
            }
        }
        searchBarHeight.constant = 400
        print("yeah im loaded bruv")
    }
    
    // prevents going out of bounds
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculateMinZoom()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme(themeChanged: false)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let rawFrame = keyboardFrame.cgRectValue
        let frame = view.convert(rawFrame, from: nil)
        let keyboardHeight = frame.height
        
        let options = UIView.AnimationOptions(rawValue: curve << 16)
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        suggestVC?.searchBtn.setImage(UIImage(named: "cross-\(theme.shared.selectedTheme == .dark ? "dark": "light")"), for: .normal)
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            if isPhone {
                self.settingsBtn.alpha = 0.0
                self.locationBtn.alpha = 0.0
                self.searchBarBottomPhone.constant = keyboardHeight + 8
                self.searchBarHeight.constant = self.view.bounds.height - keyboardHeight - 40
            } else { // iPad
                let searchBarY = self.searchBar.frame.origin.y
                let height = self.view.bounds.height - keyboardHeight - searchBarY - 16
                self.searchBarHeight.constant = max(48, height)
            }
            self.searchBar.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let queryEmpty = suggestVC?.searchField.text?.isEmpty ?? true
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              queryEmpty else { return } // if field isn't empty - don't hide tableview
        
        let options = UIView.AnimationOptions(rawValue: curve << 16)
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        
        suggestVC?.searchBtn.setImage(UIImage(named: "search-\(theme.shared.selectedTheme == .dark ? "dark": "light")"), for: .normal)

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            if isPhone {
                self.settingsBtn.alpha = 1.0
                self.locationBtn.alpha = 1.0
                self.searchBarBottomPhone.constant = 8
            }
            self.searchBarHeight.constant = 48
            self.searchBar.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func themeChanged() {
        applyTheme(themeChanged: true)
    }
    
    private func applyTheme(themeChanged: Bool) {
        let isDark = theme.shared.selectedTheme == .dark
        searchBar.addBlur(isDark: isDark, tag: 4039)
        
        // colors are automatically adjusted by palette
        settingsBtn.backgroundColor = palette.secondaryBackground
        settingsBtn.setImage(UIImage(named: "gear-\(isDark ? "dark" : "light")"), for: .normal)
        locationBtn.backgroundColor = palette.secondaryBackground
        locationBtn.setImage(UIImage(named: "location-\(isDark ? "dark" : "light")"), for: .normal)
        suggestVC?.searchBtn.setImage((self.searchBarHeight.constant == 48) ? UIImage(named: "search-\(isDark ? "dark" : "light")") : UIImage(named: "cross-\(isDark ? "dark" : "light")"), for: .normal)
        
        if let map = mapLayer, themeChanged {
            map.reloadMap()
        }
    }
    
    func showResultVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let newVC = storyboard.instantiateViewController(withIdentifier: "ResultVC") as? resultVC else { return }
        
        guard let oldVC = suggestVC else { return }

        oldVC.willMove(toParent: nil)

        addChild(newVC)

        newVC.view.frame = searchBar.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let result = searchResult {
            newVC.result = result
        }
        searchBar.addSubview(newVC.view)

        oldVC.view.removeFromSuperview()
        oldVC.removeFromParent()
        newVC.didMove(toParent: self)
    }
    
    @objc private func mapTypeChanged() {
        guard let map = mapLayer else { return }
        map.reloadMap()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navVC = storyboard.instantiateViewController(withIdentifier: "SettingsNavVC") as? UINavigationController else { return }
        
        navVC.modalPresentationStyle = .formSheet
        navVC.modalTransitionStyle = .coverVertical
        
        self.present(navVC, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        gotoGPS()
    }
    
    // MARK: Map things
    
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
    
    private func updateDotLocation(lat: Double, lon: Double) {
        let coords = gpsMgr.tranformCoordinate(lat, lon, withZoom: 17)
        let pixelX = CGFloat(coords.x * 256)
        let pixelY = CGFloat(coords.y * 256)
        let dotPos = CGPoint(x: pixelX, y: pixelY)
        
        if locationDotView == nil {
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
            
            mapLayer.addSubview(dot)
            locationDotView = dot
        }
        
        locationDotView?.center = dotPos
        updateDotScale()
    }
    
    private func gotoCoords(lat: Double, lon: Double, animated: Bool) {
        print("FOUND IT!! Lat: \(lat), Lon: \(lon)")
        let coords = gpsMgr.tranformCoordinate(lat, lon, withZoom: 17)
        let pixelX = CGFloat(coords.x * 256)
        let pixelY = CGFloat(coords.y * 256)
        let targetOffset = CGPoint(
            x: pixelX - (scrollView.bounds.width / 2),
            y: pixelY - (scrollView.bounds.height / 2)
        )
        scrollView.zoomScale = 1.0
        scrollView.setContentOffset(targetOffset, animated: animated)
    }
    
    private func gotoGPS() {
        guard let lat = currentLat, let lon = currentLon else { return }
        gotoCoords(lat: lat, lon: lon, animated: true)
    }
}
