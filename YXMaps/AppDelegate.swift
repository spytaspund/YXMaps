//
//  AppDelegate.swift
//  YXMaps
//
//  Created by spytaspund on 14.07.2026.
//

import Foundation
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootVC = storyboard.instantiateInitialViewController() else {
            print("No Initial VC found in storyboard!")
            return true
        }
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        return true
    }
}
