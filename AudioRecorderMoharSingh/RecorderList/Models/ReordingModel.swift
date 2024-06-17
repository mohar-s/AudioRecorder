//
//  ReordingModel.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class ReordingModel: NSObject {

    var title  = ""
    
    init(title: String) {
        self.title = title.replacingOccurrences(of: " ", with: "_")
    }
    
}
