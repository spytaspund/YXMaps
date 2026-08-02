//
//  ui.swift
//  YXMaps
//
//  Created by spytaspund on 31.07.2026.
//  UI stuff (extensions, helpers)
//

import Foundation
import UIKit

extension UIView {
    func addBlur(isDark: Bool, tag: Int = 4040) {
        removeBlur(tag: tag)
        self.backgroundColor = .clear
        
        if #available(iOS 8.0, *) { // iOS 8+
            let style: UIBlurEffect.Style
            if #available(iOS 13.0, *) {
                style = isDark ? .systemMaterialDark : .systemMaterialLight
            } else {
                style = isDark ? .dark : .light
            }
            
            let blurEffect = UIBlurEffect(style: style)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.tag = tag
            blurView.frame = self.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.insertSubview(blurView, at: 0)
        } else { // iOS 6-7 hahaHAHHAHAAHAHhAHhHAHAHAAHAHAAH
            let toolbar = UIToolbar(frame: self.bounds)
            toolbar.tag = tag
            toolbar.barStyle = isDark ? .black : .default
            toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            toolbar.clipsToBounds = true
            if #available(iOS 7.0, *) {
                toolbar.isTranslucent = true // translucent toolbar on iOS 6 looks kinda ugly
            } else {
                toolbar.isTranslucent = false
            }
            self.insertSubview(toolbar, at: 0)
        }
    }
    
    func removeBlur(tag: Int = 4040) {
        self.viewWithTag(tag)?.removeFromSuperview()
    }
}
