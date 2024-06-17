//
//  NewRecordingVC.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit
import AVFoundation
import AudioToolbox

class NewRecordingVC: UIViewController {
    
    var viewModel : NewRecordingViewModel!
    
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var startPauseBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var animationView: UIImageView!
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "New Recording  - \(self.viewModel.recordingObj.title)"
        timeLbl?.text = "No Recording in progress"
        updateUI()
        
        viewModel.initializeTimer {
            let str = self.viewModel.getTimerStr()
            self.timeLbl?.text = str
        }
        

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    func setViewModel(viewModel : NewRecordingViewModel)  {
        self.viewModel = viewModel
    }
    
    func updateUI()  {
        if viewModel.sessionRecorder.isRecording() {
            timeLbl?.text = "Recording in progress"
            self.startPauseBtn.setTitle("Pause", for: .normal)
            animationView?.image = UIImage.gifImageWithName("play_record")
            viewModel.pauseResume(isPause: false)
        }  else if viewModel.sessionRecorder.isPaused() {
            self.startPauseBtn.setTitle("Resume", for: .normal)
            animationView?.image = nil
            viewModel.pauseResume(isPause: true)
        } else {
            timeLbl?.text = "No Recording in progress"
            self.startPauseBtn.setTitle("Start", for: .normal)
            animationView?.image = nil
            viewModel.pauseResume(isPause: true)
        }

        self.stopBtn.isEnabled = !viewModel.sessionRecorder.isStoped()
        
    }
    
    
    // IBAction Methods
    @IBAction func startPauseRecodingBtnAction(_ sender: Any) {
        
        if viewModel.sessionRecorder.isStoped() {
            viewModel.sessionRecorder.startRecording()
        } else if viewModel.sessionRecorder.isPaused() {
            try! viewModel.sessionRecorder.resumeRecording()
        } else {
            viewModel.sessionRecorder.pauseRecording()
        }
        
        updateUI()
    }
    
    @IBAction func stopRecodingBtnAction(_ sender: Any) {
        viewModel.pauseResume(isPause: true)
        viewModel.resetTimer()
        viewModel.sessionRecorder.stopRecording()
        updateUI()
    }
    

}
