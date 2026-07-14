# FreeWheel

The `FreeWheel` bucket demonstrates ads managed by FreeWheel (linear and companion). The single sample, **BasicFreeWheelPlayer**, bridges Brightcove to FreeWheel and builds a per-session ad request with a pre-roll, two mid-rolls, and a post-roll.

## Requirements

- **Platform:** iOS.
- **Minimum OS:** iOS 14.0.
- **Toolchain:** Xcode 15.0+.
- **Extra SDKs:** the FreeWheel AdManager SDK ("AdManager Dynamic Build"), added manually — the Brightcove FreeWheel plugin comes via Swift Package Manager.

## Setup

1. Open `BasicFreeWheelPlayer.xcodeproj` in Xcode; Swift Package Manager resolves the Brightcove SDK on the first build.
2. Download the FreeWheel **"AdManager Dynamic Build"** from the [FreeWheel website](https://hub.freewheel.tv/display/techdocs/AdManager+SDK+Integration+Downloads) and drag `AdManager.xcframework` onto the project, adding it to the BasicFreeWheelPlayer target.
3. Set `AdManager.xcframework` to **Embed & Sign** under the target's Frameworks, Libraries and Embedded Content.

The FreeWheel demo endpoint constants are at the top of `ViewController.swift`.

## Key files

| File | Responsibility |
|---|---|
| `BasicFreeWheelPlayer/ViewController.swift` | Builds the FreeWheel session provider, ad-context policy, and temporal ad slots |
| `BasicFreeWheelPlayer/AppDelegate.swift` | Configures `AVAudioSession` for playback |
