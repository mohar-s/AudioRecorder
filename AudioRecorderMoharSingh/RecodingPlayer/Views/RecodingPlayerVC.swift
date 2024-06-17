//
//  RecodingPlayerVC.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit

class RecodingPlayerVC: UIViewController {
    
    @IBOutlet weak var playerProgress: UIProgressView!
    @IBOutlet weak var elapsedTextLbl: UILabel!
    @IBOutlet weak var remainingTextLbl: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var animationView: UIImageView!
    
    var viewModel : RecordingPlayerViewModel! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = viewModel.recordingObj.title
        updatePlayStatus()
        
        viewModel.playerModel.setPlayerProgress {
            self.updatePlayStatus()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        viewModel.playerModel.pause()
        super.viewWillDisappear(animated)
    }
    
    func setViewModel(viewModel : RecordingPlayerViewModel)  {
        self.viewModel = viewModel
    }
    
    func updatePlayStatus()  {
        
        playerProgress.progress = Float(viewModel.playerModel.playerProgress)
        let image = viewModel.playerModel.isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playPauseBtn?.setImage(image, for: .normal)
        
        if viewModel.playerModel.isPlaying {
            animationView?.image = UIImage.gifImageWithName("play_record")
        } else {
            animationView?.image = nil
        }
        
        elapsedTextLbl?.text = viewModel.playerModel.playerTime.elapsedText
        remainingTextLbl?.text = viewModel.playerModel.playerTime.remainingText
        
    }
    
    
    
    // IBAction Methods
    @IBAction func backwordBtnAction(_ sender: Any) {
        viewModel.playerModel.skip(forwards: false)
    }
    
    @IBAction func forwardBtnAction(_ sender: Any) {
        viewModel.playerModel.skip(forwards: true)
    }
    
    @IBAction func playPauseBtnAction(_ sender: Any) {
        viewModel.playerModel.playOrPause()
        updatePlayStatus()
        
    }
    
    @IBAction func playbackSpeedBtnAction(_ segment: UISegmentedControl) {
        let current = segment.selectedSegmentIndex
        
        switch current {
        case 0:
            viewModel.playerModel.playbackRate = 0.5
        case 1:
            viewModel.playerModel.playbackRate = 1
        case 2:
            viewModel.playerModel.playbackRate = 2
        case 3:
            viewModel.playerModel.playbackRate = 3
        default:
            print("")
        }
        
    }

}
