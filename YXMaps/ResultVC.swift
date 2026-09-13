//
//  ResultVC.swift
//  YXMaps
//
//  Created by spytaspund on 16.08.2026.
//

import Foundation
import UIKit

class resultVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var triviaLabel: UILabel!
    @IBOutlet weak var ratingBar: UIProgressView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var workingHours: UILabel!
    @IBOutlet weak var routeTypeIcon: UIImageView!
    @IBOutlet weak var routeTrivia: UILabel!
    
    let tabSegCtrl = UISegmentedControl(items: ["Overview", "Photos", "Reviews"])
    var currentTab: Int = 0
    var result: yxData.searchResult? {
        didSet {
            if isViewLoaded {
                DispatchQueue.main.async {
                    self.showSearchData()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        
        tabSegCtrl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: Notification.Name("themeChanged"),
            object: nil
        )
        showSearchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeChanged()
    }
    
    @objc private func themeChanged() {
        let isDark = theme.shared.selectedTheme == .dark
        
        headerView.backgroundColor = palette.secondaryBackground
        headingLabel.textColor = palette.textColor
        closeBtn.setImage(UIImage(named: "cross-\(isDark ? "dark" : "light")"), for: .normal)
        
        triviaLabel.textColor = palette.secondaryLabel
        ratingLabel.textColor = palette.textColor
        workingHours.textColor = palette.secondaryLabel
        routeTypeIcon.image = UIImage(named: "metro-\(isDark ? "dark" : "light")")
        routeTrivia.textColor = palette.secondaryLabel
        
        tableView.backgroundColor = palette.backgroundColor
        tableView.separatorColor = isDark ? UIColor(white: 0.25, alpha: 1.0) : nil
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func showSearchData() {
        guard let res = result else { return }
        
        headingLabel.text = res.title ?? "Без названия"
        triviaLabel.text = res.address ?? res.description ?? ""
        
        if let val = res.ratingData?.ratingValue {
            ratingBar.progress = val / 5.0
        } else {
            ratingBar.progress = 0.0
        }
        
        let rVal = res.ratingData?.ratingValue ?? 0.0
        let rCount = res.ratingData?.ratingCount ?? 0
        ratingLabel.text = String(format: "%.1f ★ (%d оценок)", rVal, rCount)
        
        workingHours.text = res.currentWorkingStatus?.text ?? "Часы работы не указаны"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 50 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = palette.backgroundColor
        
        tabSegCtrl.frame = CGRect(x: 16, y: 8, width: tableView.bounds.width - 32, height: 34)
        header.addSubview(tabSegCtrl)
        
        return header
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentTab {
        case 0: return 5
        case 1: return 1
        case 2: return 10
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() // temporary ofc
    }
    
    @objc private func tabChanged(_ sender: UISegmentedControl) {
        currentTab = sender.selectedSegmentIndex
        // update bottom buttons
        tableView.reloadData()
    }
}
