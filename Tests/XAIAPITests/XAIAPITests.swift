import Testing
import XAIAPI
import XAIAPITypes
import OpenAPIRuntime
import UsefulThings
#if os(Linux)
@preconcurrency import struct Foundation.URL
@preconcurrency import struct Foundation.Data
@preconcurrency import class Foundation.FileManager
#else
import struct Foundation.URL
import struct Foundation.Data
import class Foundation.FileManager
#endif

struct XAIAPITests {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    static let speechFileURL = repoRoot.appendingPathComponent("60s_speech.wav")

    static func makeClient() throws -> Client {
        guard
            let apiKey = getEnvironmentVariable("XAI_API_KEY", from: repoRoot.appendingPathComponent(".env")),
            !apiKey.isEmpty
        else {
            throw XAIAPITestsError.missingAPIKey
        }
        return try createClient(apiKey: apiKey)
    }

    enum XAIAPITestsError: Error, CustomStringConvertible {
        case missingAPIKey

        var description: String {
            switch self {
            case .missingAPIKey:
                "Set XAI_API_KEY in the environment (e.g. via direnv) or in a .env file at the repository root."
            }
        }
    }

    @Test func speechFileExists() throws {
        #expect(FileManager.default.fileExists(atPath: Self.speechFileURL.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: Self.speechFileURL.path)
        let size = attributes[.size] as? Int
        #expect((size ?? 0) > 0)
    }

    @Test(.enabled(if: Self.hasAPIKey)) func transcribeSpeechFile() async throws {
        let client = try Self.makeClient()
        let audioData = try Data(contentsOf: Self.speechFileURL)

        let multipartBody: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .file(
                .init(
                    payload: .init(body: HTTPBody(audioData)),
                    filename: "60s_speech.wav"
                )
            )
        ]

        let response = try await client.transcribeSpeech(
            .init(body: .multipartForm(multipartBody))
        )

        let result = try response.ok.body.json
        #expect(!result.text.isEmpty)
        #expect(result.duration > 50 && result.duration < 70)
        #expect(!result.language.isEmpty)
    }

    @Test(.enabled(if: Self.hasAPIKey)) func transcribeSpeechFileWithOptions() async throws {
        let client = try Self.makeClient()
        let audioData = try Data(contentsOf: Self.speechFileURL)

        let multipartBody: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .language(.init(payload: .init(body: HTTPBody("en")))),
            .format(.init(payload: .init(body: HTTPBody("true")))),
            .keyterm(.init(payload: .init(body: HTTPBody("Grok")))),
            .file(
                .init(
                    payload: .init(body: HTTPBody(audioData)),
                    filename: "60s_speech.wav"
                )
            ),
        ]

        let response = try await client.transcribeSpeech(
            .init(body: .multipartForm(multipartBody))
        )

        let result = try response.ok.body.json
        #expect(!result.text.isEmpty)
        #expect(result.duration > 50 && result.duration < 70)

        let words = try #require(result.words)
        #expect(!words.isEmpty)
        for word in words {
            #expect(!word.text.isEmpty)
            #expect(word.end >= word.start)
        }
    }

    static var hasAPIKey: Bool {
        guard
            let apiKey = getEnvironmentVariable("XAI_API_KEY", from: repoRoot.appendingPathComponent(".env")),
            !apiKey.isEmpty
        else { return false }
        return true
    }
}
