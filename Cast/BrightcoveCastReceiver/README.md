# Casting — Brightcove CAF receiver (BrightcoveCastReceiver)

Casts to **Brightcove's Cast Application Framework (CAF) receiver** via `BCOVGoogleCastManager(forBrightcoveReceiverApp:)` configured with a `BCOVReceiverAppConfig`. Unlike the default Google receiver, the Brightcove receiver supports DRM-protected video, SSAI, and `HLSv3` or superior.

The Brightcove CAF receiver's application id is `341387A3`, assigned to `kBCOVCAFReceiverApplicationID`; you can verify it in the [CAF receiver config.json](https://players.brightcove.net/videojs-chromecast-receiver/2/config.json).

> **Note:** When using the Brightcove receiver with the native SDK you must send the `catalogParams` object through the `customData` interface — a static URL is not supported. Using `BCOVReceiverAppConfig` handles this for you.

## Key files

| File | Responsibility |
|---|---|
| `BrightcoveCastReceiver/ViewController.swift` | `BCOVReceiverAppConfig` and `BCOVGoogleCastManager(forBrightcoveReceiverApp:)` |
| `BrightcoveCastReceiver/AppDelegate.swift` | `GCKCastContext` setup with the Brightcove receiver app id |

See the [Casting README](../) for shared setup.
