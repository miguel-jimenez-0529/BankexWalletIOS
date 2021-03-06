//
//  TokenInfoListCell.swift
//  BankexWallet
//
//  Created by Антон Григорьев on 23.07.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit

class TokenInfoListCell: UITableViewCell {
    
    @IBOutlet weak var parameterLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var measurmentLabel: UILabel!
    
    func configure(with parameter: String?, value: String?, measurment: String?) {
        parameterLabel.text = parameter ?? ""
        valueLabel.text = value ?? ""
        measurmentLabel.text = measurment ?? ""
    }
}
