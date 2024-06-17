//
//  RecordingTableCell.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class RecordingTableCell: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(recoding : ReordingModel)  {
        titleLbl?.text = recoding.title
    }

}
