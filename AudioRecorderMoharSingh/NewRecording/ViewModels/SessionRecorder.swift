//
//  SessionRecording.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import UIKit
import AVFAudio


enum RecordingState {
  case recording, paused, stopped
}

class SessionRecorder: NSObject {

    static var shared = SessionRecorder()
    
   
    
    private var engine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var state: RecordingState = .stopped
    var converter: AVAudioConverter!
    var compressedBuffer: AVAudioCompressedBuffer?
    
    private var fileName = ""
    
    
    override init() {
      super.init()
      setupSession()
      setupEngine()
    }
    
    func setFileName(fileName : String)  {
        self.fileName = fileName
    }
    
    func closeTheRecorder() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord)
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        
        mixerNode.removeTap(onBus: 0)
        engine.stop()
        
    }
    
    fileprivate func setupSession() {
      let session = AVAudioSession.sharedInstance()
      try? session.setCategory(.playAndRecord)
      try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        
        
    }
    
    
    fileprivate func setupEngine() {
      engine = AVAudioEngine()
      mixerNode = AVAudioMixerNode()

      // Set volume to 0 to avoid audio feedback while recording.
      mixerNode.volume = 0

      engine.attach(mixerNode)

      makeConnections()
      
      // Prepare the engine in advance, in order for the system to allocate the necessary resources.
      engine.prepare()
    }

    fileprivate func makeConnections() {
      let inputNode = engine.inputNode
      let inputFormat = inputNode.outputFormat(forBus: 0)
      engine.connect(inputNode, to: mixerNode, format: inputFormat)

      let mainMixerNode = engine.mainMixerNode
      let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: false)
      engine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }
    
    func startRecording() {
        
        do {
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                } catch(let error) {
                    print(error.localizedDescription)
                }
        
        let tapNode: AVAudioNode = mixerNode
        let format = tapNode.outputFormat(forBus: 0)
        
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // AVAudioFile uses the Core Audio Format (CAF) to write to disk.
        // So we're using the caf file extension.
        let fileURL = FileManagerHelper.getFileURL(for: fileName) //documentURL.appendingPathComponent("recording.caf")
        
        let file = try! AVAudioFile(forWriting: fileURL, settings: format.settings)
        
//        var delegate = UIApplication.shared.delegate as? AppDelegate
//        delegate?.filePath = fileURL
        
        tapNode.installTap(onBus: 0, bufferSize: 4096, format: format, block: {
            (buffer, time) in
            print("time sampleTime\(time.sampleTime)")
            print("time sampleTime\(time.audioTimeStamp)")
            
            try! file.write(from: buffer)
        })
        
        try! engine.start()
        state = .recording
    }
    
    
    
//    func startRecording()  {
//        let tapNode: AVAudioNode = mixerNode
//          let format = tapNode.outputFormat(forBus: 0)
//
//          var outDesc = AudioStreamBasicDescription()
//          outDesc.mSampleRate = format.sampleRate
//          outDesc.mChannelsPerFrame = 1
//          outDesc.mFormatID = kAudioFormatFLAC
//
//          let framesPerPacket: UInt32 = 1152
//          outDesc.mFramesPerPacket = framesPerPacket
//          outDesc.mBitsPerChannel = 24
//          outDesc.mBytesPerPacket = 0
//
//          let convertFormat = AVAudioFormat(streamDescription: &outDesc)!
//          converter = AVAudioConverter(from: format, to: convertFormat)
//
//          let packetSize: UInt32 = 8
//          let bufferSize = framesPerPacket * packetSize
//        
//        let fileURL = FileManagerHelper.getFileURL(for: fileName)
//
//          tapNode.installTap(onBus: 0, bufferSize: bufferSize, format: format, block: {
//            [weak self] (buffer, time) in
//            guard let weakself = self else {
//              return
//            }
//
//              
//            weakself.compressedBuffer = AVAudioCompressedBuffer(
//              format: convertFormat,
//              packetCapacity: packetSize,
//              maximumPacketSize: weakself.converter.maximumOutputPacketSize
//            )
//
//            // input block is called when the converter needs input
//            let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
//              outStatus.pointee = AVAudioConverterInputStatus.haveData;
//              return buffer; // fill and return input buffer
//            }
//
//              
//            // Conversion loop
//            var outError: NSError? = nil
//            weakself.converter.convert(to: weakself.compressedBuffer!, error: &outError, withInputFrom: inputBlock)
//
//            let audioBuffer = weakself.compressedBuffer!.audioBufferList.pointee.mBuffers
//            if let mData = audioBuffer.mData {
//              let length = Int(audioBuffer.mDataByteSize)
//              let data: NSData = NSData(bytes: mData, length: length)
//              // Do something with data
//                try! data.write(to: fileURL, options: .atomic)
//                
//            }
//            else {
//              print("error")
//            }
//          })
//
//          try! engine.start()
//          state = .recording
//    }
    
    func resumeRecording() throws {
      try engine.start()
      state = .recording
    }

    func pauseRecording() {
      engine.pause()
      state = .paused
    }

    func stopRecording() {
      // Remove existing taps on nodes
//      mixerNode.removeTap(onBus: 0)
//      
//      engine.stop()
//      state = .stopped
        
        mixerNode.removeTap(onBus: 0)
         engine.stop()
//         converter.reset()
         state = .stopped
        
        
    }
    
    
    func isRecording() -> Bool {
        return state == .recording
    }
    
    func isPaused() -> Bool {
        return state == .paused
    }
    
    func isStoped() -> Bool {
        return state == .stopped
    }
    
    
    
}

extension NSData {

    func write(withName name: String) -> URL {

        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)

        try! write(to: url, options: .atomicWrite)

        return url
    }
}
