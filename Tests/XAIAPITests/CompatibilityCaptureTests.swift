import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
import XAIAPI
import XAIAPIAsyncHTTPClient
import XAIAPITypes

// Explicitly opt in after sourcing .envrc; ordinary offline verification skips these requests.
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["XAI_CAPTURE_FIXTURES"] == "1"))
struct CompatibilityCaptureTests {
    @Test func remoteURLAndRepeatedKeyterms() async throws {
        let client = try makeClient(capture: "remote-url-keyterms")
        let body: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .keyterm(.init(payload: .init(body: HTTPBody("Marcus")))),
            .keyterm(.init(payload: .init(body: HTTPBody("florist")))),
            .url(.init(payload: .init(body: HTTPBody(
                "https://res.cloudinary.com/deepgram/video/upload/v1682106551/devex/florist_altodz.mp3"
            )))),
        ]
        let result = try await client.transcribeSpeech(.init(body: .multipartForm(body)))
        let transcript = try result.ok.body.json
        #expect(!transcript.text.isEmpty)
        #expect(transcript.text.localizedCaseInsensitiveContains("Marcus"))
        #expect(transcript.text.localizedCaseInsensitiveContains("florist"))
    }

    @Test func nonAudioFileWithInvalidFormat() async throws {
        let client = try makeClient(capture: "invalid-format")
        let body: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .format(.init(payload: .init(body: HTTPBody("not-a-boolean")))),
            .file(.init(payload: .init(body: HTTPBody("not audio")), filename: "invalid.txt")),
        ]
        let response = try await client.transcribeSpeech(.init(body: .multipartForm(body)))
        #expect(try response.badRequest.body.json.error.contains("Failed to decode audio"))
    }

    @Test func nonAudioFile() async throws {
        let client = try makeClient(capture: "non-audio")
        let body: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .file(.init(payload: .init(body: HTTPBody("not audio")), filename: "invalid.txt")),
        ]
        let response = try await client.transcribeSpeech(.init(body: .multipartForm(body)))
        #expect(try response.badRequest.body.json.error.contains("Failed to decode audio"))
    }

    private func makeClient(capture: String) throws -> Client {
        guard let apiKey = ProcessInfo.processInfo.environment["XAI_API_KEY"], !apiKey.isEmpty else {
            throw XAIAPITests.XAIAPITestsError.missingAPIKey
        }
        return Client.asyncHTTPClient(
            serverURL: URL(string: "https://api.x.ai")!,
            authentication: .bearer(apiKey),
            middlewares: [CaptureResponse(name: capture)]
        )
    }
}

private struct CaptureResponse: ClientMiddleware {
    let name: String

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let (response, responseBody) = try await next(request, body, baseURL)
        let bytes: [UInt8]
        if let responseBody {
            bytes = try await [UInt8](collecting: responseBody, upTo: 1_048_576)
        } else {
            bytes = []
        }
        let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Resources/Responses")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(bytes).write(to: directory.appendingPathComponent("\(name).json"))
        try "HTTP \(response.status.code)\nContent-Type: \(response.headerFields[.contentType] ?? "")\n"
            .write(to: directory.appendingPathComponent("\(name).txt"), atomically: true, encoding: .utf8)
        return (response, HTTPBody(bytes))
    }
}
