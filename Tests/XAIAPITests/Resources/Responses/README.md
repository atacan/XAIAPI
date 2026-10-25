# xAI speech-to-text live captures

Captured on 2026-10-25 against `POST https://api.x.ai/v1/stt`. JSON files are the
unedited response bytes. Matching `.txt` files record the HTTP status and, for SDK
captures, the response Content-Type. The curl invalid-key capture recorded only
the status. No request authorization headers or credentials are stored.

| Fixture | Request | Status |
| --- | --- | --- |
| `invalid-key.json` | Fixed invalid bearer token; one `url=https://example.com/audio.wav` part with `Content-Type: text/plain`, sent by curl | 400 |
| `invalid-format.json` | SDK parts: `format=not-a-boolean`, then `file=not audio`, filename `invalid.txt` | 400 |
| `non-audio.json` | SDK part: `file=not audio`, filename `invalid.txt` | 400 |
| `remote-url-keyterms.json` | SDK parts: `keyterm=Marcus`, `keyterm=florist`, then the public HTTPS audio `url` below | 200 |

The remote audio is Deepgram's public eleven-second florist phone-call sample:
`https://res.cloudinary.com/deepgram/video/upload/v1682106551/devex/florist_altodz.mp3`.
Both requested terms occur in the returned transcript. The authenticating SDK
client used the unmodified swift-openapi-runtime 1.12.0 encoder, including its
closing `--boundary--\r\n\r\n`. This request succeeds without trimming the epilogue.
The SDK encoded all value/file bodies as `text/plain`, with the file last for
upload cases. The successful transcript and the official docs support retaining
repeated keyterm parts; transcription bias itself is probabilistic, so this is
not proof of how the server weights each supplied term.

The invalid-format request also contains invalid audio. Its error reports audio
decoding, so it does not establish boolean-field validation behavior. Both
invalid-audio bodies contain only `error`; the invalid-key body also contains
`code`. None of these checks returned 401, 415, 422, or 429. No rate limit or
permission failures were induced. Accordingly, the overlay changes only the
confirmed HTTP 400 body and makes `ErrorResponse.code` optional.

Repeat SDK captures intentionally from the repository root (real API calls):

```bash
source .envrc
XAI_CAPTURE_FIXTURES=1 swift test --filter CompatibilityCaptureTests
```

Repeat the invalid-key capture without a real credential:

```bash
curl --silent --show-error --max-time 60 --request POST https://api.x.ai/v1/stt \
  --header 'Authorization: Bearer invalid' \
  --form 'url=https://example.com/audio.wav;type=text/plain' \
  --output Tests/XAIAPITests/Resources/Responses/invalid-key.json \
  --write-out '%{http_code}\n'
```

Update the matching status metadata if a future capture changes it.
`AuthenticationTests` decodes the captured error bodies through the generated
client entirely offline and checks the repeated keyterm/file part ordering.
