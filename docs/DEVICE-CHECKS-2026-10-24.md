# Device checks, 2026-10-24

Builds: Shazamer 1.0.4 (`61907a2`), Muzika 0.1.2 (`9a017f1`), Sixify 0.2.4 (`f939876`), Tubie 0.4.4 (`8176993`). Both architecture jobs passed for every app. Shazamer's sanitizer/native fingerprint, audible-signal and handoff-helper checks also passed, including a real Shazam response for the music fixture.

## Actual device coverage

| Check | iPad, iOS 6.1.3 | iPhone, iOS 16.7.16 rootless |
| --- | --- | --- |
| Recognize NEXTIME's СВЕТЛАНА! with the microphone | Passed on 1.0.3 | Passed on 1.0.3 |
| Quiet recording shows the quiet-audio message | Passed | Passed |
| Favorite, restart, persistent favorite, restore original state | Passed | Passed |
| Search by artist, favorites filter, available song metadata | Passed | Passed |
| Muzika handoff reaches actual playing state | Passed, including 1.0.4 | Passed |
| Tubie handoff opens the correct music video | Passed; player rate 1.0 and progress advancing | Passed |
| Sixify handoff reaches actual playing state | Not checked: logged out | Passed with existing session |
| Return to Shazamer after each receiver without process termination | Passed for Muzika | Passed on 1.0.4 for all three receivers |

The iPhone initially produced scene-update watchdog reports during 1.0.3 handoffs from an incoming debug URL. The captured main-thread stack resolved to `+[SZUtils handoffTrack:toScheme:directURL:]` and the synchronous URL open, not DSP. Version 1.0.4 defers opening until the current callback returns and uses the asynchronous modern API. The repeated receiver checks retain the same Shazamer process and produce no new watchdog reports.

Four screenshots from each real device show Home, song detail, Favorites and history search. They were captured on 1.0.3 after the final visual fixes; 1.0.4 changes only external URL dispatch. The screenshots contain an actual microphone recognition result. No fabricated recognition/history fixtures were inserted. Temporary test favorites were restored.

## Additional checks not exercised on devices

- Audible no-match retry and cancellation at every timing boundary; the implementation limits it to one extra capture.
- Network-loss/offline retry and old pending-item duration fallback.
- Deleting a middle row from a multi-result filtered list.
- Ambiguous catalog results, absent receiver apps, and every direct provider-link variation.
- All device orientations and other hardware/iOS versions.

Native helper tests cover quiet PCM, DC offset, an isolated click, a sustained tone, validated provider IDs, false hosts, Cyrillic matching and unwanted recording versions. Those checks do not substitute for the unexercised UI cases above.

## Classic UI completion (1.0.5)

Both architecture builds and fingerprint sanitizer checks passed in run 40081321877, commit d831870e2c05173376a5c4e946881c30a37aca06. Checked main, detail, favorites, search and Settings on iOS 6.1.3 and iOS 16.7.16. Modern iOS uses classic capsule switches, glossy navigation buttons, pinstriped grouped settings, embossed headings, app dialogs/menus and full-screen iPhone app windows. Native iOS 5/6 controls remain in use on old devices. System share sheets, keyboards and pickers retain the installed OS appearance. The displayed Settings version is read from the installed bundle.

Screenshots were refreshed; temporary favorites used for screenshots were restored to their original values. The smallest 29 px icon has negligible 2/255 corner alpha from antialiasing; other sizes, including the public icon, have zero-alpha corners.

Long messages in classic app alerts remain scrollable.
