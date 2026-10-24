import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
import XAIAPI
import XAIAPITypes
import XAIAPIURLSession

struct URLSessionFactoryTests {
    @Test func decodesSpeechResponse() async throws {
        let client = Client.urlSession(
            serverURL: URL(string: "https://offline.invalid")!,
            authentication: .bearer("offline-token"),
            middlewares: [FixtureResponse()]
        )
        let response = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        let value = try response.ok.body.json
        #expect(value.text == "Hello")
        #expect(value.duration == 3.45)
        #expect(value.words?.first?.start == 0.24)
    }

    @Test func forwardsExplicitRuntimeConfiguration() async throws {
        let client = Client.urlSession(
            serverURL: URL(string: "https://offline.invalid")!,
            configuration: .init(
                multipartBoundaryGenerator: ConstantMultipartBoundaryGenerator(boundary: "offline-boundary")
            ),
            middlewares: [FixtureResponse(expectedBoundary: "offline-boundary")]
        )
        let response = try await client.transcribeSpeech(.init(body: .multipartForm([])))
        #expect(try response.ok.body.json.language == "en")
    }
}

// Short-circuits the request before either transport: no sockets or credentials are used.
private struct FixtureResponse: ClientMiddleware {
    var expectedBoundary: String? = nil

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        #expect(operationID == "transcribeSpeech")
        #expect(request.method == .post)
        #expect(request.path == "/v1/stt")
        if let expectedBoundary {
            #expect(request.headerFields[.contentType]?.contains(expectedBoundary) == true)
        }
        return (
            HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]),
            HTTPBody(#"{"text":"Hello","language":"en","duration":3.45,"words":[{"text":"Hello","start":0.24,"end":0.48}]}"#)
        )
    }
}
