//
//  PlaceTableViewCell.swift
//  MapKitApp
//
//  Created by selinay ceylan on 15.03.2024.
//

import UIKit

class PlaceTableViewCell: UITableViewCell {

    @IBOutlet weak var iimageView: UIImageView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
