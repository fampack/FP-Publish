//
//  FeedTableViewCell.swift
//  FP
//
//  Created by Bajrang on 19/08/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {

    @IBOutlet weak var imgUserImageView: UIImageView!
    
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblFeedDate: UILabel!
    @IBOutlet weak var lblFeedTitle: UILabel!
    @IBOutlet weak var lblFeedComment: UILabel!
    
    @IBOutlet weak var imgFeedImageView: UIImageView!
    
    @IBOutlet weak var btnChat: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
