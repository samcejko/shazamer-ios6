# Recognized-song playback handoff (unreleased)

Source changes only. No builds, version bumps or deployments were performed. End-to-end playback must be checked after building Shazamer and the three receiving apps.

The previous sender used `muzika://isrc/<code>`, a route Muzika never implemented. It also used `spotify:search:`, which belongs to the official Spotify scheme rather than Sixify's registered schemes. `canOpenURL` only confirms ownership of a scheme; it cannot verify that a path is implemented or that playback started.

## Protocol

Prefer existing routes when a direct recording link is known:

- `muzika://open?url=<encoded canonical YouTube watch URL>`
- `tubie://open?url=<encoded canonical YouTube watch URL>`
- `sixify://open?uri=<encoded spotify:track:ID>` (or `spot6://open`)

Without a direct service ID, send `SCHEME://search?q=...&autoplay=1&title=...&artist=...&isrc=...&duration=...`. Duration is seconds. All values are percent encoded, including nested percent signs, Unicode, ampersands and plus signs. Existing receivers still show ordinary search results; upgraded receivers recognize the autoplay flag before the normal search/debug branches. The new receivers also accept the equivalent `SCHEME://play?title=...` form.

Muzika uses its existing ISRC/title/artist/duration matcher on a worker, then starts the player and opens Now Playing. Sixify searches its catalog and checks title, artist, unwanted versions and duration before playback. Tubie uses a validated YouTube ID when available; otherwise it checks video search candidates and opens the selected video with its existing autoplaying watch controller. Uncertain candidates remain search results for manual choice. A newer external link invalidates an older lookup; a changed music-player track also wins over a pending lookup.

The Foundation-only helpers in `tools/MusicHandoff.h` are copied identically into Shazamer's `src/Util/` and each receiver's `src/`. They validate exact hostnames and recording IDs, exclude unsupported link shapes such as Spotify albums/playlists, and normalize match text. Keep the copies synchronized. Shazamer's Info.plist includes the sibling schemes in `LSApplicationQueriesSchemes` for modern iOS.

## Deferred device checks

- Cold launch and already-running launch of all three receivers from a recognized song.
- Both a known direct provider link and metadata-only recognition, including ISRC and no-ISRC cases.
- Full playback starts, rather than only navigation. Spotify still needs a working signed-in session; playback availability follows each receiver's existing backend.
- Search-only behavior with an older receiver, and browser/provider fallback when the sibling app is absent.
- Reject false hostnames and unsupported IDs; handle titles/artists containing `&`, `+`, `%`, accents and non-Latin text.
- No automatic cover/live/remix selection when the requested recording does not contain that version marker. Unknown/ambiguous results remain available for manual choice.
- Trigger two handoffs quickly and choose another track while matching; an old lookup must not interrupt the new choice.
- No-network, no-result and unavailable-track behavior must show the existing error/search UI without starting unrelated audio.

Static review passed: UTF-8 decoding and source delimiters, valid Info.plist with required scheme allowlist, identical helper copies, receiver handlers outside debug mode, and duplicate-free new translations. No device playback test has been performed for these source changes.
