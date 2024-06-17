//
//  FileManagerHelper.swift
//  AudioRecorderMoharSingh
//
//  Created by Mohar on 31/05/24.
//

import Foundation
struct FileManagerHelper {
    static let filename = "audio.wav"
    static let FILEEXT = ".wav"

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func getAllFiles() -> [String] {
        var list = [String]()
        do {
            let path = getDocumentsDirectory()
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: nil
            )
            
            for url in directoryContents {
                if checkFileExit(from: url) {
                    list.append(url.lastPathComponent.replacingOccurrences(of: FILEEXT, with: ""))
                } else {
                    print("File not found \(url.lastPathComponent)")
                }
            }
        } catch (let error) {
            
        }
        
        return list
    }
    
    static func getFileURL(for fileName: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(fileName+FILEEXT)
        return path as URL
    }
    
    static func removeFile(from url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    static func checkFileExit(from url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path())
    }
    
}
