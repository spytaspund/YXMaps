//
//  SearchCells.swift
//  YXMaps
//
//  Created by spytaspund on 15.08.2026.
//

import Foundation
import UIKit

class headingCell: UITableViewCell {
    let heading = UILabel()
    let subtitle = UILabel()
    
    let headingSize = 24.0
    
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
        contentView.backgroundColor = palette.secondaryBackground
        
        heading.backgroundColor = .clear
        heading.textColor = palette.textColor
        heading.text = "Point on map"
        heading.font = UIFont.boldSystemFont(ofSize: headingSize)
        
        subtitle.backgroundColor = .clear
        subtitle.textColor = palette.secondaryLabel
        subtitle.text = "Connect to the Internet to see details."
        subtitle.font = UIFont.systemFont(ofSize: 15)
        subtitle.numberOfLines = 20 // idk if i need to set the specific and non obscure amount
        contentView.addSubview(heading)
        contentView.addSubview(subtitle)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellWidth = contentView.bounds.width
        let cellHeight = contentView.bounds.height
        let padding = 8.0
        let subtitlePadding = 6.0
        
        heading.frame = CGRect(
            x: padding,
            y: subtitlePadding,
            width: cellWidth - subtitlePadding*2,
            height: headingSize + 2
        )
        
        subtitle.frame = CGRect(
            x: padding,
            y: headingSize + padding + 2,
            width: cellWidth - padding*2,
            height: cellHeight - headingSize - padding*2 - subtitlePadding
        )
    }
    
    func updateColors() {
        self.backgroundColor = palette.secondaryBackground
        contentView.backgroundColor = palette.secondaryBackground
        
        heading.textColor = palette.textColor
        
        subtitle.textColor = palette.secondaryLabel
    }
}
