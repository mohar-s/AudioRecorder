//
//  RecordingListViewModel.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class RecordingListViewModel: NSObject {

    var recordingList = [ReordingModel]()
    
    func loadPreviousRecording()  {
        let allFile = FileManagerHelper.getAllFiles()
        
        for file in allFile {
            recordingList.append(ReordingModel(title: file))
        }
    }
    
}
