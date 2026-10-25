We generate the Swift code using swift-openapi-generator. As we apply complex transformations to the original OpenAPI specification, we use a Python tool to do this. Run the generation with 

```bash
make regenerate
```

As this is a Swift package, you can find the code of the Swift package dependencies in the ".build/checkouts/" directory. Look at that folder when you need to understand how to use the code from the Swift package dependencies.

The package exposes XAIAPITypes, XAIAPI, XAIAPIURLSession, and
XAIAPIAsyncHTTPClient. Keep transport imports out of the core and Types targets.
Shared authentication belongs in Sources/XAIAPI/Authentication/;
Client+Authentication.swift supports custom transports. Never edit generated
operation security metadata directly.

Use the two factory examples in README.md. The AsyncHTTPClient factory and
createClient(apiKey:) helper retain a ten-minute timeout. The provider helper is
in the AsyncHTTPClient target. Preserve existing transcription tests when editing
the manifest. Read live-test credentials from ProcessInfo; keep dependencies version-based for SwiftPM releases.

Validate offline explicitly:

```bash
swift build
swift test --filter 'URLSessionFactoryTests|AsyncHTTPClientFactoryTests|AuthenticationTests|ResponseModelTests'
```

Do not run the full suite for offline verification: XAIAPITests contains live API
tests that automatically detect credentials in the process environment. Never
print credentials or include them in test failures.

If response conversion reports `Expected date string to be ISO8601-formatted`,
inspect the actual timestamp format. The current specification uses numeric
seconds, with no date-time properties. Fractional-second date strings in a future
spec may require configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds)
in both factories. Keep caller overrides and test decoding through both factories.
Direct Client initialization bypasses factory defaults; standalone JSONDecoder
instances need their own dateDecodingStrategy. Regeneration preserves helper and
documentation edits, so keep them outside generated directories.
