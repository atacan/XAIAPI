# XAIAPI

Swift client for the xAI speech-to-text API, generated from `original_openapi.yaml`
with fixes from `openapi-overlay.yaml`.

| Product | Contents |
| --- | --- |
| `XAIAPITypes` | Generated models, operation inputs/outputs, and API protocol |
| `XAIAPI` | Shared generated client and authentication; accepts any `ClientTransport` |
| `XAIAPIURLSession` | `Client.urlSession(...)` factory |
| `XAIAPIAsyncHTTPClient` | `Client.asyncHTTPClient(...)` factory and `createClient(apiKey:)` helper |

Add the core product and your chosen convenience product to your application's
target dependencies. Add Types if you import it directly. Both factories return
`XAIAPI.Client` and use the same operation-aware bearer authentication.

```swift
import Foundation
import XAIAPI
import XAIAPIURLSession

let client = Client.urlSession(
    serverURL: URL(string: "https://api.x.ai")!,
    authentication: .bearer("YOUR_XAI_API_KEY")
)
```

```swift
import Foundation
import XAIAPI
import XAIAPIAsyncHTTPClient

let client = Client.asyncHTTPClient(
    serverURL: URL(string: "https://api.x.ai")!,
    authentication: .bearer("YOUR_XAI_API_KEY")
)
// Or use the provider helper with the generated server URL:
let providerClient = try createClient(apiKey: "YOUR_XAI_API_KEY")
```

The AsyncHTTPClient factory and provider helper use a ten-minute request timeout
for transcription. The URLSession factory uses its transport's default settings.
Both accept `configuration:`, `transportConfiguration:`, and `middlewares:`.
Explicit configuration overrides are forwarded. To inject a session or HTTP client,
import and declare the corresponding upstream transport product directly; the
application owns its lifecycle. Do not shut down a shared transport client.

Dynamic credentials can use `Authentication.bearer { try await tokenStore.accessToken() }`.
Authentication follows the final OpenAPI security requirements. Missing credentials
fail before sending a protected operation. Factories default to `.none`, so supply
`.bearer(...)` for xAI requests. Additional middleware runs before authentication.
For a custom transport, use
`Client(serverURL:configuration:transport:authentication:middlewares:)` from core.

Regenerate after specification or overlay changes:

```bash
make regenerate
swift build
swift test --filter 'URLSessionFactoryTests|AsyncHTTPClientFactoryTests|AuthenticationTests|ResponseModelTests'
```

These selected suites use in-memory fixtures and never call the API. The separate
`XAIAPITests` suite includes live transcription tests that read `XAI_API_KEY` from
the environment or `.env`; run those only when intended. Keep real credentials
out of source files and examples.

Generated sources and operation security metadata are rewritten on regeneration.
The manifest, helpers, tests, documentation, and overlay are preserved. Keep manual
edits outside `GeneratedSources/` and `Authentication/GeneratedSecurity/`.

For `Expected date string to be ISO8601-formatted`, inspect the response format
before changing factory defaults. This specification uses numeric seconds for
speech timestamps and has no `date-time` properties. If a future specification
adds fractional-second dates, configure both factories with
`.init(dateTranscoder: .iso8601WithFractionalSeconds)` and retain caller overrides.

The core and Types targets have no transport dependency. Both transport packages
remain declared at package level and may still be resolved by SwiftPM or Xcode.
Run `make help` for other development commands. Dependency source is available in
`.build/checkouts/`.
