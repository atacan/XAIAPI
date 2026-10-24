import Foundation
import Testing
import XAIAPITypes

struct ResponseModelTests {
    @Test func decodesRequiredResponseWithOmittedOptionalCollections() throws {
        let value = try JSONDecoder().decode(
            Components.Schemas.SpeechToTextResponse.self,
            from: Data(#"{"text":"Hello","language":"en","duration":3.45}"#.utf8)
        )
        #expect(value.duration == 3.45)
        #expect(value.words == nil)
        #expect(value.channels == nil)
    }

    @Test func decodesWordTimestampsAsNumericSeconds() throws {
        let word = try JSONDecoder().decode(
            Components.Schemas.TranscriptionWord.self,
            from: Data(#"{"text":"Hello","start":0.24,"end":0.48,"speaker":1}"#.utf8)
        )
        #expect(word.start == 0.24)
        #expect(word.end == 0.48)
        #expect(word.speaker == 1)
        #expect(word.confidence == nil)
    }
}
