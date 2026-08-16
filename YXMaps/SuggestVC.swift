//
//  SuggestVC.swift
//  YXMaps
//
//  Created by spytaspund on 15.08.2026.
//

import Foundation
import UIKit

class suggestVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchBtn: UIButton!
    
    let suggestCellID = "suggestCell"
    let headingCellID = "headingCell"
    var suggestResults: [yxData.suggestResult] = []
    var searchSymCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchField.addTarget(self, action: #selector(searchQueryChanged(_:)), for: .editingChanged)
        resultsTable.delegate = self
        resultsTable.dataSource = self
        
        resultsTable.register(suggestCell.self, forCellReuseIdentifier: suggestCellID)
        resultsTable.register(headingCell.self, forCellReuseIdentifier: headingCellID)
        resultsTable.contentInset = .zero
        resultsTable.scrollIndicatorInsets = .zero
        resultsTable.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeChanged),
            name: Notification.Name("themeChanged"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestResults.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 100 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: suggestCellID, for: indexPath) as! suggestCell
        let result = suggestResults[indexPath.row]
        let isDark = theme.shared.selectedTheme == .dark
        let tag = result.tags.first ?? "locality"
        
        cell.iconName = tag.toIconName(isDark: isDark)
        cell.updateColors()
        cell.heading.text = result.title.text
        cell.subtitle.text = result.subtitle.text
        cell.distance.text = result.distance.text
        
        return cell
    }
    
    @objc func searchQueryChanged(_ textField: UITextField) {
        guard let query = textField.text, !query.isEmpty else { return }
        
        searchSymCount += 1
        let currentCount = searchSymCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.searchSymCount == currentCount else { return }
            yxapi.shared.suggest(query: query, lat: 38.5, lon: 55.5) { results in
                if let suggestResults = results {
                    self.suggestResults = suggestResults
                    DispatchQueue.main.async {
                        self.resultsTable.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchField.text = ""
        searchSymCount += 1
        suggestResults.removeAll()
        resultsTable.reloadData()
        
        view.endEditing(true) // should automatically trigger keyboardWillHide
    }
    
    @objc func themeChanged() {
        applyTheme()
    }
    
    private func applyTheme() {
        let isDark = theme.shared.selectedTheme == .dark
        
        searchField.backgroundColor = palette.secondaryBackground
        searchField.textColor = palette.textColor
        searchField.keyboardAppearance = isDark ? .dark : .light
        if searchField.isFirstResponder {
            searchField.reloadInputViews()
        }
        
        resultsTable.backgroundColor = palette.backgroundColor
        resultsTable.separatorColor = isDark ? UIColor(white: 0.25, alpha: 1.0) : nil
        
        DispatchQueue.main.async {
            self.resultsTable.reloadData()
        }
    }
}
