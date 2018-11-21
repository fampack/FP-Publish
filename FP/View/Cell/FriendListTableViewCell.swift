//
//  FriendListTableViewCell.swift
//  FP
//
//  Created by Bajrang on 18/08/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import UIKit

class FriendListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgUserImageView: UIImageView!
    
    @IBOutlet weak var lblUserName: UILabel!
    
    @IBOutlet weak var btnReject: UIButton!
    @IBOutlet weak var btnAccept: UIButton!
    
    @IBOutlet var lblUserNameTrailingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
