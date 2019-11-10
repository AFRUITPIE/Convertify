//
//  TrackTableViewCell.swift
//  Convertify
//
//  Created by Hayden Hong on 11/4/19.
//  Copyright © 2019 Hayden Hong. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    // MARK: Properties

    @IBOutlet var trackNameLabel: UILabel!
    @IBOutlet var artistNameLabel: UILabel!
    @IBOutlet var albumArtImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
