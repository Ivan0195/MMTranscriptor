import Foundation
import SwiftWhisper
import AVFoundation
import AudioKit
import AVKit

public struct SubtitleSentence: Identifiable, Codable {
    public let id: String
    public let sentence: String
    public let start: TimeInterval
    public let end: TimeInterval
    
    init(sentence: String, start: TimeInterval, end: TimeInterval) {
        self.id = UUID().uuidString
        self.sentence = sentence
        self.start = start
        self.end = end
    }
}

public struct MMTranscriptor {
    
    var whisper: Whisper
    var whisperParams: WhisperParams = WhisperParams(strategy: .greedy)
    let clock = ContinuousClock()
    
    public init (modelURL: URL, language: WhisperLanguage) {
        whisperParams.detect_language = false
        whisperParams.translate = false
        whisperParams.language = language
        whisper = Whisper(fromFileURL: modelURL, withParams: whisperParams)
    }
    
    public func convertMovToMP4(fileUrl: URL) async throws -> URL? {
        let avAsset = AVURLAsset(url: fileUrl, options: nil)
        var url: URL? = nil
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            print("error in export session")
            return url
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                return url
            }
        }
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        await exportSession.export()
        url = exportSession.outputURL
        return url
    }
    
    private func convertAudio (fileURL: URL) -> [Float] {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false
        var floatsArray: [Float] = []
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                print("Error converting audio: \(error)")
                return
            }
            let data = try! Data(contentsOf: tempURL)
            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }
            try? FileManager.default.removeItem(at: tempURL)
            floatsArray = floats
        }
        return floatsArray
    }
    
    public func transcribe (url: URL) async throws -> [SubtitleSentence]? {
        
        var trackUrl = url
        var transcript: [SubtitleSentence] = []
        
        if url.pathExtension == "mov" {
            do {
                trackUrl = try await self.convertMovToMP4(fileUrl: url)!
            } catch {
                return transcript
            }
        }
        do {
            let floatArray = self.convertAudio(fileURL: trackUrl)
            let segments = try await whisper.transcribe(audioFrames: floatArray)
            transcript = segments.map {SubtitleSentence(sentence: $0.text, start: TimeInterval($0.startTime), end: TimeInterval($0.endTime))}
        } catch {
            return transcript
        }
        return transcript
    }
}
