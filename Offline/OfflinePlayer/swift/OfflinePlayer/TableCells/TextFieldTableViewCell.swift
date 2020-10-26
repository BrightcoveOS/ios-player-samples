//
//  TextFieldTableViewCell.swift
//  OfflinePlayer
//
//  Copyright © 2020 Brightcove, Inc. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }

}
