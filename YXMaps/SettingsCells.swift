//
//  SettingsCells.swift
//  YXMaps
//
//  Created by spytaspund on 01.08.2026.
//  i HATE iOS 6!!!!!!!!!!
//

import Foundation
import UIKit

class themeCell: UITableViewCell {
    let label = UILabel()
    let themeSegCtrl = UISegmentedControl()
    var selectedTheme: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        selectionStyle = .none
        
        self.backgroundColor = palette.secondaryBackground
        
        label.text = "Theme" // would be good to add translations
        label.textColor = palette.textColor
        label.backgroundColor = .clear
        
        themeSegCtrl.insertSegment(withTitle: "Light", at: 0, animated: false)
        themeSegCtrl.insertSegment(withTitle: "Dark", at: 1, animated: false)
        if #available(iOS 13.0, *) {
            themeSegCtrl.insertSegment(withTitle: "System", at: 2, animated: false)
        }
        themeSegCtrl.addTarget(self, action: #selector(themeSelected(_:)), for: .valueChanged)
        
        contentView.addSubview(label)
        contentView.addSubview(themeSegCtrl)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellWidth = contentView.bounds.width
        let cellHeight = contentView.bounds.height
        
        let segWidth: CGFloat = (themeSegCtrl.numberOfSegments > 2) ? 200.0 : 140.0
        let segHeight: CGFloat = 30.0
        
        label.frame = CGRect(
            x: 16,
            y: (cellHeight - 21) / 2.0,
            width: cellWidth - segWidth - 16,
            height: 21
        )
        
        themeSegCtrl.frame = CGRect(
            x: cellWidth - segWidth - 16,
            y: (cellHeight - segHeight) / 2.0,
            width: segWidth,
            height: segHeight
        )
    }
    
    func updateColors() {
        self.backgroundColor = palette.secondaryBackground
        self.contentView.backgroundColor = palette.secondaryBackground
        label.textColor = palette.textColor
    }
    
    @objc private func themeSelected(_ sender: UISegmentedControl) {
        selectedTheme?(sender.selectedSegmentIndex)
    }
}

class mapTypeCell: UITableViewCell {
    let label = UILabel()
    let segCtrl = UISegmentedControl()
    var mapType: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        selectionStyle = .none // don't highlight cell on selection
        
        self.backgroundColor = palette.secondaryBackground
        
        label.text = "Map type"
        label.textColor = palette.textColor
        label.backgroundColor = .clear
        
        segCtrl.insertSegment(withTitle: "Scheme", at: 0, animated: false)
        segCtrl.insertSegment(withTitle: "Satellite", at: 1, animated: false)
        segCtrl.addTarget(self, action: #selector(mapTypeSelected(_:)), for: .valueChanged)
        
        contentView.addSubview(label)
        contentView.addSubview(segCtrl)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let segWidth: CGFloat = 140.0
        let segHeight: CGFloat = 30.0
        
        let cellWidth = contentView.bounds.width
        let cellHeight = contentView.bounds.height
        
        label.frame = CGRect(
            x: 16,
            y: (cellHeight - 21) / 2.0,
            width: cellWidth - segWidth - 48,
            height: 21
        )
        
        segCtrl.frame = CGRect(
            x: cellWidth - segWidth - 16,
            y: (cellHeight - segHeight) / 2,
            width: segWidth,
            height: segHeight
        )
    }
    
    func updateColors() {
        self.backgroundColor = palette.secondaryBackground
        self.contentView.backgroundColor = palette.secondaryBackground
        label.textColor = palette.textColor
    }
    @objc private func mapTypeSelected(_ sender: UISegmentedControl) {
        mapType?(sender.selectedSegmentIndex)
    }
}
