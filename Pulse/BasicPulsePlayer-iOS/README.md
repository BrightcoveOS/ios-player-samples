# BasicPulsePlayer (iOS)

INVIDI Pulse ads on iOS, driven by a table of 12 ad scenarios (pre/mid/post-roll, skippable, frequency capping, pause ads, mid-session extension, and error cases) with a companion ad slot.

## Key files

| File | Responsibility |
|---|---|
| `BasicPulsePlayer/ViewController.swift` | Pulse session provider, companion slot, scenario table, session extension |
| `BasicPulsePlayer/BCOVPulseVideoItem.swift` | Maps a `Library.json` entry to a Pulse request |
| `BasicPulsePlayer/Library.json` | The 12 ad-scenario definitions |

Requires the manually-added INVIDI Pulse and Open Measurement SDKs — see the [Pulse README](../) for setup.
