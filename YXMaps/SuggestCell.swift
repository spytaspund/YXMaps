//
//  SuggestCell.swift
//  YXMaps
//
//  Created by spytaspund on 04.08.2026.
//

import Foundation
import UIKit

class suggestCell: UITableViewCell {
    let iconContainer = UIView()
    let icon = UIImageView()
    let heading = UILabel()
    let subtitle = UILabel()
    let distance = UILabel()
    
    var iconName = "locality-light"
    
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
        distance.textColor = palette.secondaryLabel
        distance.backgroundColor = .clear
        distance.textAlignment = .right
        distance.font = UIFont.systemFont(ofSize: 15)
        
        iconContainer.layer.cornerRadius = 8
        iconContainer.backgroundColor = palette.backgroundColor
        icon.backgroundColor = .clear
        icon.image = UIImage(named: iconName)
        
        contentView.addSubview(heading)
        contentView.addSubview(subtitle)
        contentView.addSubview(distance)
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(icon)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellWidth = contentView.bounds.width
        let cellHeight = contentView.bounds.height
        let padding = 8.0
        let iconPadding = 6.0
        let iconSize = 30.0
        let distanceWidth = 100.0
        
        iconContainer.frame = CGRect(
            x: padding,
            y: padding,
            width: iconSize,
            height: iconSize
        )
        
        icon.frame = CGRect(
            x: iconPadding,
            y: iconPadding,
            width: iconSize - iconPadding*2,
            height: iconSize - iconPadding*2
        )
        
        distance.frame = CGRect(
            x: cellWidth - distanceWidth - padding,
            y: padding,
            width: distanceWidth,
            height: 21
        )
        
        let headingX = iconContainer.frame.maxX + padding

        heading.frame = CGRect(
            x: headingX,
            y: padding,
            width: distance.frame.minX - headingX - padding,
            height: 21
        )
        subtitle.frame = CGRect(
            x: headingX,
            y: heading.frame.maxY + 4.0,
            width: cellWidth - headingX - padding,
            height: cellHeight - (heading.frame.maxY + 4) - padding
        )
    }
    
    func updateColors() {
        self.backgroundColor = palette.secondaryBackground
        self.contentView.backgroundColor = palette.secondaryBackground
        icon.image = UIImage(named: iconName)
        iconContainer.backgroundColor = palette.backgroundColor
        heading.textColor = palette.textColor
        subtitle.textColor = palette.secondaryLabel
        distance.textColor = palette.secondaryLabel
    }
}
