# Shazamer

A standalone retro music recognition app targeting **jailbroken iOS 5–10 devices (ARMv7)**, with an **ARM64 IPA targeting iOS 14+** and a **rootless ARM64 package for iOS 15+**, preserving the authentic skeuomorphic iOS 6 aesthetic. These are the same deployment targets and package requirements as RealNews.

Recognition has been checked on real devices with iOS 6.1.3 and iOS 16.7.16. Other versions in the target ranges have not been exercised on hardware. Installing the ARM64 IPA requires a compatible installer such as TrollStore; the IPA's minimum OS version does not imply that the installer supports every newer OS release.

Tap the iconic glossy blue Shazam button, let the radar listen to ambient audio, and receive track metadata, high-resolution album artwork, and full song lyrics in seconds.

Because Shazam's API (`amp.shazam.com`) requires modern TLS 1.2/1.3 with cipher suites unsupported by the legacy iOS 6 networking stack, Shazamer embeds its own TLS engine (Mbed TLS) and raw HTTP/1.1 client. All recognition requests and acoustic fingerprint calculations happen directly on-device without any third-party proxy or relay servers.

---

## Features

- **Direct On-Device Recognition**: Captures 16 kHz 16-bit mono audio through `AudioQueue`, runs a pure C 2048-point radix-2 FFT with Hanning windowing, extracts landmark peaks across 4 frequency bands (250–5500 Hz), packages the binary Shazam fingerprint with IEEE 802.3 CRC32, and sends it directly to Shazam's Discovery API.
- **Pure Skeuomorphic iOS 6 UI**:
  - 180 pt tactile recognition button with radial electric-blue gradient, metallic rim, embossed inner bevel, and glass gloss arc.
  - CoreGraphics vector rendering of the official Shazam logo.
  - Multi-ring animated sonar radar reactive to live microphone decibel levels.
  - Dark carbon and linen textures, glossy navigation bars, and classic grouped table views.
- **Comprehensive Song Details**:
  - High-resolution album artwork cached on-device.
  - Track title, artist, album name, musical genre, and release year.
  - Full-screen scrollable lyrics reader with automatic sync detection.
- **Local App Ecosystem Integration**:
  - One-tap playback launch buttons for:
    - **Muzika** (`muzika://search?q=...`)
    - **Spot6** (`spotify://search?query=...`)
    - **Tubie** (`tubie://search?q=...`)
  - Universal web fallbacks for Apple Music, Spotify, and YouTube.
- **Tag History & Offline Queue**:
  - Persistent tag history stored locally in `History.plist`.
  - Album art thumbnails and swipe-to-delete.
  - Offline mode: captures audio signatures when offline and queues them for automatic re-querying once network connectivity is restored.
- **User Preferences**:
  - Auto-listen on app launch.
  - Vibration on successful song match.
  - Configurable listening duration (4s, 7s, 10s, 12s).
  - Default preferred music player selector.
- **URL Scheme**:
  - Trigger recognition from external apps, web links, or activator actions via `shazamer://tag`.
- **Bilingual Support**: Full native English (`en`) and Czech (`cs`) localizations.

---

## Download

Packages are generated automatically on every release:

| Target Platform | Architecture | Package Format |
| --- | --- | --- |
| **iOS 5–10 (Classic)** | 32-bit `armv7` | `Shazamer-<version>.ipa` or `com.samcejko.shazamer_<version>_iphoneos-arm.deb` |
| **iOS 15+ (Rootless Jailbreak)** | 64-bit `arm64` | `com.samcejko.shazamer_<version>_iphoneos-arm64.deb` |
| **iOS 14+ (IPA; compatible installer required)** | 64-bit `arm64` | `Shazamer-<version>-arm64.ipa` |

---

## Installation

### iOS 5–10 (32-bit Jailbreak)
1. Add the Cydia repository: `http://repo.samcejko.eu/`
2. Search for **Shazamer** and install.
3. *Alternative manual install*:
   - Ensure **AppSync Unified** and **IPA Installer Console** are installed.
   - Transfer `Shazamer.ipa` via SCP or iFunBox and run:
     ```sh
     ipainstaller -f Shazamer.ipa
     ```
   - Or install the Debian package via terminal:
     ```sh
     dpkg -i com.samcejko.shazamer_1.0.4_iphoneos-arm.deb && uicache
     ```

### ARM64: IPA targeting iOS 14+, rootless package requiring iOS 15+
- **TrollStore on a compatible OS**: Download `Shazamer-1.0.4-arm64.ipa` in Safari, open with TrollStore, and tap **Install**.
- **Rootless Jailbreak (iOS 15+)**: Install `com.samcejko.shazamer_1.0.4_iphoneos-arm64.deb` via Sileo / Zebra or `dpkg -i`.

---

## Building

The project is compiled using Theos and GitHub Actions (`.github/workflows/build.yml`):
- `armv7` target: iOS 9.3 SDK, minimum deployment target 5.0; package requires iOS 5.0 through 10.x.
- `arm64` target: iOS 16.5 SDK, minimum deployment target 14.0.
- The rootless ARM64 Debian package requires iOS 15.0 or newer, independently of the binary/IPA minimum.

### Automated GitHub CI Workflow
Push changes or trigger builds remotely using the provided PowerShell scripts:
```powershell
.\tools\gh-push.ps1 -Message "Implement new feature"
.\tools\gh-build.ps1 -Download -Install
```

---

## Project Structure

```
shazamer-ios6/
├── control                      # Theos package metadata (com.samcejko.shazamer)
├── Makefile                     # Dual armv7/arm64 build rules
├── entitlements.xml             # iOS 6 fake-signing entitlements
├── entitlements-arm64.xml       # Modern iOS entitlements
├── Resources/
│   ├── Info.plist               # App bundle configuration & microphone permissions
│   ├── cacert.pem               # Root CA certificates bundle for Mbed TLS
│   ├── en.lproj/                # English localization strings
│   └── cs.lproj/                # Czech localization strings
├── src/
│   ├── main.m                   # Application entry point
│   ├── SZAppDelegate.h/.m       # App lifecycle & URL scheme routing
│   ├── SZCommon.h/.m            # Global constants & error definitions
│   ├── Audio/
│   │   └── SZAudioRecorder.h/.m # CoreAudio AudioQueue 16kHz mono recorder
│   ├── DSP/
│   │   ├── SZFFT.h/.c           # Pure C 2048-point radix-2 DIT FFT
│   │   └── SZSignatureGenerator.h/.m # Shazam landmark fingerprint generator
│   ├── Net/
│   │   ├── SZTLSSocket.h/.m     # Mbed TLS socket transport
│   │   ├── SZHTTPRequest.h/.m   # HTTP/1.1 client with TLS
│   │   └── SZShazamClient.h/.m  # Shazam API client & artwork fetcher
│   ├── Model/
│   │   ├── SZTrack.h/.m         # Track metadata & lyrics model
│   │   ├── SZHistoryStore.h/.m  # History persistence & offline queue
│   │   └── SZSettings.h/.m      # Application settings & user defaults
│   ├── Theme/
│   │   └── SZTheme.h/.m         # Colors, skeuomorphic gradients, and bar styles
│   ├── UI/
│   │   ├── SZTagButton.h/.m     # Glossy Shazam button with vector logo
│   │   ├── SZRadarView.h/.m     # Dynamic expanding sonar ripple view
│   │   ├── SZMainViewController.h/.m # Primary tag & radar screen
│   │   ├── SZTrackViewController.h/.m # Track details, actions, & artwork
│   │   ├── SZLyricsViewController.h/.m # Lyrics viewer modal
│   │   ├── SZHistoryViewController.h/.m # History table & offline retry
│   │   └── SZSettingsViewController.h/.m # Settings table view
│   └── Util/
│       ├── SZModern.h/.m        # iOS 6 to modern iOS compatibility layer
│       └── SZUtils.h/.m         # Deep linking, web fallbacks, & helpers
├── tools/
│   ├── icon.svg                 # 1024x1024 master skeuomorphic vector icon
│   ├── gen_assets.py            # Automated icon & launch image rasterizer
│   ├── modern_bundle.py         # Modern asset catalog & plist patcher
│   ├── gh-push.ps1              # GitHub REST API commit & push utility
│   └── gh-build.ps1             # GitHub Actions CI trigger & package fetcher
└── vendor/
    ├── mbedtls_config_ios6.h    # Lightweight Mbed TLS compile configuration
    └── mbedtls_glue.c           # Entropy & platform integration
```

---

## License

This project is licensed under the [MIT License](LICENSE).
Third-party component licenses are detailed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
