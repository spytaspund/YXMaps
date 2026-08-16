//
//  ResultVC.swift
//  YXMaps
//
//  Created by spytaspund on 16.08.2026.
//

import Foundation
import UIKit

class resultVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    
    let tabSegCtrl = UISegmentedControl(items: ["Overview", "Photos", "Reviews"])
    var currentTab: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = headerView
        
        tabSegCtrl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
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
