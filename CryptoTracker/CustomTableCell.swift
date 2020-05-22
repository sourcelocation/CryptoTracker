//
//  CustomTableCell.swift
//  CryptoTracker
//
//  Created by iMac on 19.05.2020.
//  Copyright © 2020 iMac. All rights reserved.
//

import UIKit

class CustomTableCell: UITableViewCell {
    @IBOutlet weak var logoImageView: ImageLoader!
    @IBOutlet weak var cryptoNameLabel: UILabel!
    @IBOutlet weak var shortCryptoNameLabel: UILabel!
    @IBOutlet weak var cryptoCountLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeInPercentsLabel: UILabel!
    
}
