# Pulse

The `Pulse` bucket demonstrates ad playback with INVIDI Technologies Pulse. The Brightcove side is the `BrightcovePulse` product (resolved via Swift Package Manager); the INVIDI Pulse SDK and INVIDI Open Measurement (OM) SDK are **not** distributed via Swift Package Manager and must be added manually to the application target.

## Samples

| Sample | Platform | What it demonstrates |
|---|---|---|
| `BasicPulsePlayer-iOS` | iOS | A table of 12 ad scenarios (pre/mid/post-roll, skippable, frequency capping, pause ads, mid-session extension, error cases) with a companion slot |
| `BasicPulsePlayer-tvOS` | tvOS | Pulse playback on tvOS with fixed content metadata and midroll positions |

## Requirements

- iOS 14.0+ / tvOS 15.0+
- Xcode 15.0+
- Brightcove SDK via Swift Package Manager (auto-resolved)
- The **INVIDI Pulse SDK added manually** — iOS also needs the INVIDI OM SDK; tvOS needs the Pulse tvOS framework only

## Setup

Open the sample's `.xcodeproj` in Xcode; Swift Package Manager resolves the Brightcove SDK on the first build. Download the INVIDI frameworks and add them to the application target before building — iOS SDKs [here](https://service.videoplaza.tv/proxy/ios-sdk/2/latest), tvOS SDK [here](https://service.videoplaza.tv/proxy/tvos-sdk/2/latest). The samples ship with a working Brightcove demo account and a test Pulse host (`kPulseHost = https://bc-test.videoplaza.tv`) — replace the host with your own.
