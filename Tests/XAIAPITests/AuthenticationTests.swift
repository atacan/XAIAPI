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

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        requestCount += 1
        authorization = request.headerFields[.authorization]
        return (
            HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]),
            HTTPBody(#"{"text":"Hello","language":"en","duration":3.45}"#)
        )
    }
}
