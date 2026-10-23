# Changelog

## [1.0.2] - 2026-10-24

- Ship the worker-stack crash fix: fingerprint histories live in heap storage, retained for the whole calculation.
- Correct the Hann window and cascading time-domain peak spreading used for recognition.
- Ship rounded installed icons in every supported size.
- Exercise the actual native fingerprint code on a 512 KiB worker stack with sanitizers, and verify a music fingerprint against Shazam before building packages.

## [1.0.0] - 2026-10-19

### Initial Release
- **Real-Time Music Recognition**: Tap the classic glossy Shazam button to capture ambient audio and identify songs in seconds.
- **Pure On-Device DSP**: Custom 2048-point radix-2 DIT real-to-complex FFT, Hanning windowing, 4-band peak extraction (250–5500 Hz), parabolic interpolation, and binary packet packing with CRC32 checksum.
- **Direct-from-Device HTTPS**: Integrated Mbed TLS stack negotiating modern TLS 1.2+ ciphers directly with Shazam's discovery API without any intermediate proxy server.
- **Reactive Sonar Radar**: Animated expanding ripple rings reflecting live microphone audio levels during capture.
- **Rich Track View**: Displays high-resolution album artwork, song title, artist name, album name, genre, and release year.
- **Full Lyrics Viewer**: Dedicated scrollable modal displaying synced/unsynced song lyrics when provided by Shazam.
- **Ecosystem Integration**: Instant launch shortcuts for local iOS 6 music apps:
  - **Muzika** (`muzika://search?q=...`)
  - **Spot6** (`spotify://search?query=...`)
  - **Tubie** (`tubie://search?q=...`)
  - Universal web fallbacks for Apple Music, Spotify, and YouTube.
- **Tag History & Offline Queue**: Keeps a local record of all identified tracks with cover art thumbnails, swipe-to-delete, and queueing of offline captures to retry once internet connectivity is restored.
- **Customizable Preferences**: Configure auto-listen on app start, vibration on successful match, listening duration (4s to 12s), and preferred default audio player.
- **URL Scheme Support**: Launch recognition directly from other apps or shortcuts via `shazamer://tag`.
- **Authentic iOS 6 Aesthetics**: Skeuomorphic glossy blue button with metallic bevels, deep glass arc reflection, textured backgrounds, and classic navigation bars.
- **Bilingual Interface**: Complete English (`en`) and Czech (`cs`) translations.
- **Dual Architecture Packages**: 32-bit `armv7` for iOS 6.x (Cydia `.deb` and `.ipa`) and 64-bit `arm64` for iOS 14–17 (rootless jailbreaks and TrollStore).
