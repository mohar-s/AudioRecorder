//
//  RecordingPlayerViewModel.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class RecordingPlayerViewModel: NSObject {

    var playerModel = PlayerViewModel.shared
        
    var recordingObj : ReordingModel! = nil
    init(recordingObj : ReordingModel) {
        self.recordingObj = recordingObj
        playerModel.initializeAudio(fileName: recordingObj.title , isforRecoding: false)
    }
    
}
