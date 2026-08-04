//
//  SuggestCell.swift
//  YXMaps
//
//  Created by spytaspund on 04.08.2026.
//

import Foundation
import UIKit

class suggestCell: UITableViewCell {
    let iconView = UIImageView()
    let heading = UILabel()
    let subtitle = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        self.backgroundColor = palette.secondaryBackground
        
        heading.textColor = palette.textColor
        heading.backgroundColor = .clear
        subtitle.textColor = palette.secondaryLabel
        subtitle.backgroundColor = .clear
        subtitle.font = UIFont.systemFont(ofSize: 15)
        subtitle.numberOfLines = 20
        
        iconView.layer.cornerRadius = 4
        iconView.backgroundColor = palette.backgroundColor
        iconView.image = UIImage(named: "locality-light")
        
        self.addSubview(iconView)
        self.addSubview(heading)
        self.addSubview(subtitle)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellWidth = contentView.bounds.width
        let cellHeight = contentView.bounds.height
        let padding = 8.0
        let iconSize = 30.0
        
        iconView.frame = CGRect(
            x: padding,
            y: padding,
            width: iconSize,
            height: iconSize
        )
        
        heading.frame = CGRect(
            x: iconSize + padding*2,
            y: padding,
            width: cellWidth - iconSize - padding*3,
            height: 21
        )
        
        subtitle.frame = CGRect(
            x: iconSize + padding*2,
            y: 21 + padding,
            width: cellWidth - iconSize - padding*3,
            height: cellHeight - 21 - padding*3
        )
    }
    
    func updateColors() {
        self.backgroundColor = palette.secondaryBackground
        iconView.image = UIImage(named: "locality-\(theme.shared.selectedTheme == .dark ? "dark" : "light")")
        heading.textColor = palette.textColor
        subtitle.textColor = palette.secondaryLabel
    }
}
