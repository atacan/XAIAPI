// Generated from the final OpenAPI specification. Regenerated; do not edit.

internal enum OperationSecurity {
    enum Scheme: Sendable {
        case bearer
        case apiKey(header: String)
        case unsupported
    }

    static let schemes: [String: Scheme] = ["bearerAuth": .bearer]
    static let defaultRequirements: [[String]] = [["bearerAuth"]]
    static let operations: [String: [[String]]] = ["transcribeSpeech": [["bearerAuth"]]]
}
