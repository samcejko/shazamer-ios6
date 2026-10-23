# Pending source changes

These changes have not been compiled, installed or exercised on iOS, per the user's instruction to defer the build. Existing installed/published version remains 1.0.2.

Before release, build both architectures and check on iOS 6 and the rootless iPhone:

- Play recognizable music: the initial recording should recognize normally.
- Use audible unrecognized sound: exactly one extra recording starts, lasting 10–15 seconds depending on the initial duration. A second no-match stops. Tap during recognition, the retry delay, and the extra recording to cancel; navigating away must also prevent a retry.
- Use silence, a constant DC signal, and a brief click: show the quiet-audio message without an API request. Quiet real music above the threshold should proceed. The threshold requires five 20 ms windows above about -55 dBFS after subtracting DC bias.
- Disable connectivity: no automatic extra recording; save the offline fingerprint with its actual duration. Old offline history entries default to 6000 ms when retried.
- Open an existing history file from 1.0.2. Missing favorite/duration fields must retain existing entries with default values.
- Star/unstar a song, restart, and verify persistence. Recognize the same song again and retain its favorite state. Repeated entries of the same track should agree.
- Search titles, artists and albums with different case/diacritics. Combine search with Favorites. Delete a middle filtered row and verify only that original object is removed. Clear search and confirm the remaining history.
- Scroll results while the keyboard is open; the keyboard must not hide the final result. Confirm empty-state messages leave the filter and search accessible.
- Toggle favorites in detail, return to history, and confirm the filter updates.
- Open a track with full metadata, one with missing metadata, and an old history entry. Long titles and album names should wrap; missing metadata is omitted, never fabricated. Duration only appears when supplied by the service.
- Follow supplied Apple Music/Spotify/YouTube links and test the existing search fallbacks where a direct link is absent.
- Inspect radar alignment in portrait/landscape, on phone/tablet, and during highlight/pulse. All rings must share the button's center.

Static checks performed locally: UTF-8 source decoding, balanced source delimiters, and complete/unique English and Czech symbolic UI localization keys (existing literal network-error fallbacks excluded). Native behavior and visual layout still require the deferred build and device checks above.
