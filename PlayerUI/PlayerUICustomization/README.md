# Control-layout customization (PlayerUICustomization)

Switches a single `BCOVPUIPlayerView` among six control layouts at runtime: the built-in `basicVOD`, `basicLive`, and `basicLiveDVR`, two custom layouts (`Simple` and `Complex`), and `nil` (no controls). It also demonstrates the PlayerUI accessibility API — `accessibilityLabelPrefix` and a `BCOVPUIButtonAccessibilityDelegate` keyed on `BCOVPUIViewTag` — plus layout manipulation such as hiding the play button on a device shake and adding a custom overlay label.

## Key files

| File | Responsibility |
|---|---|
| `PlayerUICustomization/ViewController.swift` | The `LayoutType` enum and runtime layout cycling; accessibility wiring |
| `PlayerUICustomization/CustomLayouts.swift` | Builds the `Simple` and `Complex` `BCOVPUIControlLayout`s |
| `PlayerUICustomization/ControlViewStyles.swift` | Colors, fonts, and slider styling for the custom layouts |
| `PlayerUICustomization/fontello.ttf` | Icon font used by the Complex layout |

The Complex layout is designed for iPad. See the [UI Customization README](../) for shared setup.
