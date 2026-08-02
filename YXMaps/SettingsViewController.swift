//
//  SettingsViewController.swift
//  YXMaps
//
//  Created by spytaspund on 31.07.2026.
//

import Foundation
import UIKit

struct settingKeys {
    static let theme = "selectedTheme"
    static let mapType = "mapTypeIndex"
}

class settingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

    private let themeCellID = "themeCell"
    private let mapCellID = "mapTypeCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 7.0, *) {
            tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
            tableView.scrollIndicatorInsets = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        } else {
            tableView.contentInset = .zero
            tableView.scrollIndicatorInsets = .zero
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(themeCell.self, forCellReuseIdentifier: themeCellID)
        tableView.register(mapTypeCell.self, forCellReuseIdentifier: mapCellID)
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    private func applyTheme() {
        view.backgroundColor = palette.backgroundColor
        tableView.backgroundColor = palette.backgroundColor
        tableView.reloadData()
        
        guard let navBar = navigationController?.navigationBar else { return }
        let isDark = theme.shared.selectedTheme == .dark
        
        if isDark {
            tableView.separatorColor = UIColor(white: 0.25, alpha: 1.0)
        } else {
            tableView.separatorColor = nil
        }
        
        if #available(iOS 13.0, *) {} else {
            navBar.barStyle = isDark ? .black : .default
            if #available(iOS 7.0, *) {
                navBar.isTranslucent = true
            } else {
                navBar.isTranslucent = false
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name("themeChanged"), object: nil)
    }
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Table view shenanigans
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 44 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { // theme cell
            let cell = tableView.dequeueReusableCell(withIdentifier: themeCellID, for: indexPath) as! themeCell
            cell.updateColors()
            cell.themeSegCtrl.selectedSegmentIndex = theme.shared.selectedTheme.rawValue
            cell.selectedTheme = { [weak self] index in
                guard let newTheme = themeType(rawValue: index) else { return }
                theme.shared.selectedTheme = newTheme
                self?.applyTheme()
            }
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: mapCellID, for: indexPath) as! mapTypeCell
            cell.updateColors()
            cell.segCtrl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: settingKeys.mapType)
            cell.mapType = { index in
                UserDefaults.standard.set(index, forKey: settingKeys.mapType)
                NotificationCenter.default.post(name: Notification.Name("mapTypeChanged"), object: index)
            }
            return cell
        }
        return UITableViewCell() // fallback
    }
}
