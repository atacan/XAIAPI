import OpenAPIRuntime
import XAIAPI
import XAIAPITypes

/// Creates a client for the xAI Inference API with a ten-minute request timeout.
public func createClient(apiKey: String) throws -> Client {
    Client.asyncHTTPClient(
        serverURL: try Servers.Server1.url(),
        authentication: .bearer(apiKey)
    )
}
