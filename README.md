Usage example:
```swift
import MMTranscriptor
import SwiftWhisper

let transcriptor = MMTranscriptor(modelURL: Bundle.main.url(forResource: "ggml-base-q5_1", withExtension: "bin"), language: .english)
let subtitles = try await transcriptor.transcribe(url: fileUrl)
```

Method .transcribe returns [SubtitleSentence]

```swift
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
```
