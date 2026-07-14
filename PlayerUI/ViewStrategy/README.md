# View strategy (ViewStrategy)

A `BCOVPlaybackController` can be built with a *view strategy* — a closure that returns the exact `UIView` used as the controller's `view`. This sample uses it to compose the SDK's video view and a custom controls view into a single container, registering the controls as a session consumer inside the closure.

## Key files

| File | Responsibility |
|---|---|
| `ViewStrategy/ViewController.swift` | Defines and uses the view-strategy closure |
| `ViewStrategy/ViewStrategyCustomControls.swift` | The composed custom-controls `UIView` |

See the [UI Customization README](../) for shared setup.
