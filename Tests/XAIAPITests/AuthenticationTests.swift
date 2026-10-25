import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
import XAIAPI
import XAIAPITypes

struct AuthenticationTests {
    @Test func bearerCredentialReachesTransport() async throws {
        let transport = RecordingTransport()
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            transport: transport,
            authentication: .bearer("offline-token")
        )
        let response = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        #expect(try response.ok.body.json.text == "Hello")
        #expect(await transport.authorization == "Bearer offline-token")
        #expect(await transport.requestCount == 1)
    }

    @Test func namedDynamicCredentialReachesTransport() async throws {
        let transport = RecordingTransport()
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            transport: transport,
            authentication: .credentials(["bearerAuth": .init(provider: { "dynamic-offline-token" })])
        )
        _ = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        #expect(await transport.authorization == "Bearer dynamic-offline-token")
    }

    @Test func repeatsKeytermPartsBeforeFile() async throws {
        let transport = RecordingTransport()
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            configuration: .init(
                multipartBoundaryGenerator: ConstantMultipartBoundaryGenerator(boundary: "offline-boundary")
            ),
            transport: transport,
            authentication: .bearer("offline-token")
        )
        let multipartBody: MultipartBody<Operations.transcribeSpeech.Input.Body.multipartFormPayload> = [
            .keyterm(.init(payload: .init(body: HTTPBody("Grok")))),
            .keyterm(.init(payload: .init(body: HTTPBody("xAI")))),
            .file(.init(payload: .init(body: HTTPBody("offline-audio")), filename: "audio.wav")),
        ]
        _ = try await client.transcribeSpeech(.init(body: .multipartForm(multipartBody)))

        let body = try #require(await transport.requestBody)
        let parts = body.components(separatedBy: "--offline-boundary")
            .filter { $0.contains("content-disposition:") }
        #expect(parts.count == 3)
        guard parts.count == 3 else { return }
        #expect(parts[0].contains("name=\"keyterm\""))
        #expect(parts[0].contains("\r\n\r\nGrok\r\n"))
        #expect(parts[1].contains("name=\"keyterm\""))
        #expect(parts[1].contains("\r\n\r\nxAI\r\n"))
        #expect(parts[2].contains("name=\"file\""))
        #expect(parts[2].contains("filename=\"audio.wav\""))
        #expect(parts[2].contains("\r\n\r\noffline-audio\r\n"))
    }

    @Test(arguments: ["invalid-key", "invalid-format", "non-audio"])
    func decodesCapturedBadRequest(name: String) async throws {
        let fixtureURL = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        let transport = RecordingTransport(status: .badRequest, responseBody: fixture)
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            transport: transport,
            authentication: .bearer("offline-token")
        )
        let response = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        let error = try response.badRequest.body.json
        #expect(!error.error.isEmpty)
        if name == "invalid-key" {
            #expect(error.code == "Client specified an invalid argument")
            #expect(error.error.contains("Incorrect API key"))
        } else {
            #expect(error.code == nil)
            #expect(error.error.contains("Failed to decode audio"))
        }
    }

    @Test func decodesCapturedRemoteURLResponse() async throws {
        let fixtureURL = try #require(Bundle.module.url(forResource: "remote-url-keyterms", withExtension: "json"))
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        let transport = RecordingTransport(responseBody: fixture)
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            transport: transport,
            authentication: .bearer("offline-token")
        )
        let response = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        let transcript = try response.ok.body.json
        #expect(transcript.text.contains("Marcus Florist"))
        #expect(transcript.language == "en")
        #expect(transcript.duration > 10 && transcript.duration < 12)
        #expect(transcript.words?.isEmpty == false)
    }

    @Test func missingCredentialFailsBeforeTransport() async throws {
        let transport = RecordingTransport()
        let client = Client(
            serverURL: URL(string: "https://offline.invalid")!,
            transport: transport,
            authentication: .none
        )
        await #expect(throws: (any Error).self) {
            _ = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        }
        #expect(await transport.requestCount == 0)
    }
}

private actor RecordingTransport: ClientTransport {
    private(set) var authorization: String?
    private(set) var requestCount = 0
    private(set) var requestBody: String?
    private let status: HTTPResponse.Status
    private let responseBody: String

    init(
        status: HTTPResponse.Status = .ok,
        responseBody: String = #"{"text":"Hello","language":"en","duration":3.45}"#
    ) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        requestCount += 1
        authorization = request.headerFields[.authorization]
        if let body {
            requestBody = try await String(collecting: body, upTo: 16_384)
        }
        return (
            HTTPResponse(status: status, headerFields: [.contentType: "application/json"]),
            HTTPBody(responseBody)
        )
    }
}
