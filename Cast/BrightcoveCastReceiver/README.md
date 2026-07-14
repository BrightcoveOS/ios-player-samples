# Casting — Brightcove CAF receiver (BrightcoveCastReceiver)

Casts to Brightcove's Cast Application Framework (CAF) receiver, configured with a `BCOVReceiverAppConfig`. Unlike the default Google receiver, the Brightcove receiver supports DRM-protected video, SSAI, and HLSv3-or-superior.

## Key files

| File | Responsibility |
|---|---|
| `BrightcoveCastReceiver/ViewController.swift` | `BCOVReceiverAppConfig` and the Brightcove cast manager |
| `BrightcoveCastReceiver/AppDelegate.swift` | Cast context setup with the Brightcove receiver app id |

> **Note:** With the Brightcove receiver you must send catalog parameters through the receiver's `customData` interface rather than a static URL; `BCOVReceiverAppConfig` handles this for you.

See the [Casting README](../) for shared setup.
