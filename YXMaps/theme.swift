//
//  theme.swift
//  YXMaps
//
//  Created by spytaspund on 01.08.2026.
//

import Foundation
import UIKit

enum themeType: Int {
    case light = 0
    case dark = 1
    case system = 2 // for iOS 13+
}

class theme {
    static let shared = theme()
    static let themeChangedNotify = Notification.Name("AppThemeChangedNotification")
    
    var selectedTheme: themeType {
        get {
            let raw = UserDefaults.standard.integer(forKey: settingKeys.theme)
            if #available(iOS 13.0, *) {
                return themeType(rawValue: raw) ?? .system
            } else {
                return themeType(rawValue: raw) == .dark ? .dark : .light
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: settingKeys.theme)
            forceTheme()
            NotificationCenter.default.post(name: theme.themeChangedNotify, object: nil)
        }
    }
    
    func forceTheme() {
        if #available(iOS 13.0, *) {
            let style: UIUserInterfaceStyle
            
            switch selectedTheme {
            case .light: style = .light
            case .dark: style = .dark
            case .system: style = .unspecified
            }
            
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

struct palette {
    static var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? .black : UIColor(white: 0.95, alpha: 1.0)
            }
        } else {
            return theme.shared.selectedTheme == .dark ? .black : UIColor(white: 0.95, alpha: 1.0)
        }
    }
    
    static var textColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
        } else {
            return theme.shared.selectedTheme == .dark ? .white : .black
        }
    }
    
    static var secondaryBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(white: 0.117, alpha: 1.0) : .white
            }
        } else {
            return theme.shared.selectedTheme == .dark ? UIColor(white: 0.117, alpha: 1.0) : .white
        }
    }
}
