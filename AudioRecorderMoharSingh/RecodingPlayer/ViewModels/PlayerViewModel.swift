//
//  PlayerViewModel.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//


import AVFoundation
import UIKit

enum TimeConstant {
    static let secsPerMin = 60
    static let secsPerHour = TimeConstant.secsPerMin * 60
}

class PlayerViewModel: NSObject {
    // MARK: Public properties
    
    static var shared = PlayerViewModel()
    
    private var progressUpdate : (() -> Void)? = nil
    
    var isPlaying = false
    var isPlayerReady = false
    var playbackRate: Double = 1.0 {
        didSet {
            updateForRateSelection()
        }
    }
    
    var playerProgress: Double = 0
    var playerTime: PlayerTime = .zero
    var meterLevel: Float = 0
    
    
    // MARK: Private properties
    
    private var engine = AVAudioEngine()
    private var mixerNode = AVAudioMixerNode()
    private let player = AVAudioPlayerNode()
    private let timeEffect = AVAudioUnitTimePitch()
    
    private var displayLink: CADisplayLink?
    
    private var needsFileScheduled = true
    
    private var audioFile: AVAudioFile?
    private var audioSampleRate: Double = 0
    private var audioLengthSeconds: Double = 0
    
    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0
    
    private var fileName = ""
    private var state: RecordingState = .stopped
    
    private var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        
        return playerTime.sampleTime
    }
    
    // MARK: - Public
    
    override init() {
        super.init()
        
        setupDisplayLink()
    }
    
    // initialize the Player with Source file
    func initializeAudio(fileName : String , isforRecoding : Bool) {
       
//        if isforRecoding {
//            setupEngine()
//        } else {
            setupAudio(fileName: fileName)
//        }
    }
    
    
    
    
    func setPlayerProgress(onProgressUpdate porgress: @escaping () -> Void)  {
        self.progressUpdate = porgress
    }
    
    func playOrPause() {
        
        isPlaying.toggle()
        
        if player.isPlaying {
            pause()
        } else {
            displayLink?.isPaused = false
            connectVolumeTap()
            
            if needsFileScheduled {
                scheduleAudioFile()
            }
            player.play()
        }
    }
    
    func pause() {
        isPlaying = false
        displayLink?.isPaused = true
        disconnectVolumeTap()
        
        player.pause()
    }
    
    func skip(forwards: Bool) {
        let timeToSeek: Double
        
        if forwards {
            timeToSeek = 10
        } else {
            timeToSeek = -10
        }
        
        seek(to: timeToSeek)
    }
    
    // MARK: - Private
    
    private func setupAudio(fileName : String) {
        
        let fileURL = FileManagerHelper.getFileURL(for: fileName)
        if FileManagerHelper.checkFileExit(from: fileURL) {
            do {
                let file = try AVAudioFile(forReading: fileURL)
                let format = file.processingFormat
                
                audioLengthSamples = file.length
                audioSampleRate = format.sampleRate
                audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
                
                audioFile = file
                
                configureEngine(with: format)
                updateDisplay()
            } catch {
                print("Error reading the audio file: \(error.localizedDescription)")
            }
        } else {
            print("file is not Available yet \(fileURL.lastPathComponent)")
        }
        
    }
    
    private func configureEngine(with format: AVAudioFormat) {
        engine.attach(player)
        engine.attach(timeEffect)
        
        engine.connect(
            player,
            to: timeEffect,
            format: format)
        engine.connect(
            timeEffect,
            to: engine.mainMixerNode,
            format: format)
        
        engine.prepare()
        
        do {
            try engine.start()
            
            scheduleAudioFile()
            isPlayerReady = true
        } catch {
            print("Error starting the player: \(error.localizedDescription)")
        }
    }
    
    private func scheduleAudioFile() {
        guard
            let file = audioFile,
            needsFileScheduled
        else {
            return
        }
        
        needsFileScheduled = false
        seekFrame = 0
        
        player.scheduleFile(file, at: nil) {
            self.needsFileScheduled = true
        }
    }
    
    // MARK: Audio adjustments
    
    private func seek(to time: Double) {
        guard let audioFile = audioFile else {
            return
        }
        
        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offset
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame
        
        let wasPlaying = player.isPlaying
        player.stop()
        
        if currentPosition < audioLengthSamples {
            updateDisplay()
            needsFileScheduled = false
            
            let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)
            player.scheduleSegment(
                audioFile,
                startingFrame: seekFrame,
                frameCount: frameCount,
                at: nil
            ) {
                self.needsFileScheduled = true
            }
            
            if wasPlaying {
                player.play()
            }
        }
    }
    
    private func updateForRateSelection() {
        
        timeEffect.rate = Float(playbackRate)
    }
    
    
    // MARK: Audio metering
    
    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }
        
        let minDb: Float = -80
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    private func connectVolumeTap() {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        
        engine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { buffer, _ in
            guard let channelData = buffer.floatChannelData else {
                return
            }
            
            let channelDataValue = channelData.pointee
            let channelDataValueArray = stride(
                from: 0,
                to: Int(buffer.frameLength),
                by: buffer.stride)
                .map { channelDataValue[$0] }
            
            let rms = sqrt(channelDataValueArray.map {
                return $0 * $0
            }
                .reduce(0, +) / Float(buffer.frameLength))
            
            let avgPower = 20 * log10(rms)
            let meterLevel = self.scaledPower(power: avgPower)
            
            DispatchQueue.main.async {
                self.meterLevel = self.isPlaying ? meterLevel : 0
            }
        }
    }
    
    private func disconnectVolumeTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
        meterLevel = 0
    }
    
    // MARK: Display updates
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateDisplay))
        displayLink?.add(to: .current, forMode: .default)
        displayLink?.isPaused = true
    }
    
    @objc private func updateDisplay() {
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        if currentPosition >= audioLengthSamples {
            player.stop()
            
            seekFrame = 0
            currentPosition = 0
            
            isPlaying = false
            displayLink?.isPaused = true
            
            disconnectVolumeTap()
        }
        
        playerProgress = Double(currentPosition) / Double(audioLengthSamples)
        
        let time = Double(currentPosition) / audioSampleRate
        playerTime = PlayerTime(
            elapsedTime: time,
            remainingTime: audioLengthSeconds - time)
        
        if let progressUpdate = progressUpdate {
            progressUpdate()
        }
    }
    
    
    
    
//    fileprivate func setupEngine() {
//      
//      // Set volume to 0 to avoid audio feedback while recording.
//      mixerNode.volume = 1
//
//      engine.attach(mixerNode)
//
//      makeConnections()
//      
//      // Prepare the engine in advance, in order for the system to allocate the necessary resources.
//      engine.prepare()
//    }
//    
//    fileprivate func makeConnections() {
//      let inputNode = engine.inputNode
//      let inputFormat = inputNode.outputFormat(forBus: 0)
//      engine.connect(inputNode, to: mixerNode, format: inputFormat)
//
//      let mainMixerNode = engine.mainMixerNode
//      let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: false)
//      engine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
//    }
//    
//    
//    
//    func startRecording() {
//        
//        do {
//                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
//                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
//                } catch(let error) {
//                    print(error.localizedDescription)
//                }
//        
//        let tapNode: AVAudioNode = mixerNode
//        let format = tapNode.outputFormat(forBus: 0)
//        
////        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        
//        // AVAudioFile uses the Core Audio Format (CAF) to write to disk.
//        // So we're using the caf file extension.
//        let fileURL = FileManagerHelper.getFileURL(for: fileName) //documentURL.appendingPathComponent("recording.caf")
//        
//        let file = try! AVAudioFile(forWriting: fileURL, settings: format.settings)
//        
//        
//        tapNode.installTap(onBus: 0, bufferSize: 4096, format: format, block: {
//            (buffer, time) in
//            try! file.write(from: buffer)
//        })
//        
//        try! engine.start()
//        state = .recording
//    }
//    
//    func resumeRecording() throws {
//      try engine.start()
//      state = .recording
//    }
//
//    func pauseRecording() {
//      engine.pause()
//      state = .paused
//    }
//
//    func stopRecording() {
//      // Remove existing taps on nodes
//      mixerNode.removeTap(onBus: 0)
//      
//      engine.stop()
//      state = .stopped
//    }
//
//    
//    func isRecording() -> Bool {
//        return state == .recording
//    }
//    
//    func isPaused() -> Bool {
//        return state == .paused
//    }
//    
//    func isStoped() -> Bool {
//        return state == .stopped
//    }
//    
//    
//    
//    
    
    
    
}
