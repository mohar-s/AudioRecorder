//
//  NewRecordingViewModel.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class NewRecordingViewModel: NSObject {

    let sessionRecorder = SessionRecorder.shared
    
    
    var timer : Timer?
    var counter = 0
    
    var recordingObj : ReordingModel! = nil
    init(recordingObj : ReordingModel) {
        self.recordingObj = recordingObj
        sessionRecorder.setFileName(fileName: recordingObj.title)
//        sessionRecorder.initializeAudio(fileName: recordingObj.title , isforRecoding: true)
        counter = 0
    }
    
    
   private var timerCompletion : (() -> Void)? = nil
    
    func initializeTimer(completion: (() -> Void)? = nil) {
        self.timerCompletion = completion
    }
    
    func getTimerStr() -> String {
        return getFormatedTimeSeconds(counter)
    }
    
    func resetTimer()  {
        counter = 0
    }
    
   private func getFormatedTimeSeconds(_ seconds: Int)  -> String {
      let (h, m, s) = secondsToHoursMinutesSeconds(seconds)
        if h >  0 {
            return"\(h) Hours, \(m) Mins, \(s) Sec"
        } else {
            return"\(m) Mins, \(s) Sec"
        }
    }
   private func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func pauseResume(isPause : Bool) {
        if !isPause{
            timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(prozessTimer), userInfo: nil, repeats: true)
        } else {
            timer?.invalidate()
        }
    }
    
    
    @objc func prozessTimer() {
        counter += 1
        if let timerCompletion = timerCompletion  {
            timerCompletion()
        }
        
    }
    
    
}
