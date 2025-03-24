# iOS products Snapshot Testing

`SDSnapshots` library provides `XCTestCase` asserts for UI screenshots comparison with reference image (and reference recording).

- [iOS products Snapshot Testing](#ios-products-snapshot-testing)
  - [Stack](#stack)
  - [Features](#features)
  - [Limitations](#limitations)
  - [Usage](#usage)
  - [Alternatives](#alternatives)
  - [License](#license)
  - [Thanks](#thanks)

## Stack

- **Xcode** 16.1
- **iOS Simulator Runtime** 18.1
- **Swift** 6.0

## Features

- Works both with `UIKit` and `SwiftUI`
- Allows to test multiple devices layout at ones, using the single simulator device launch (cover iPhones, iPads, Split Views in a single test case)
- Respects device orientation and safe area. Applies it from test run `SnapshotDevice` specification (not simulator's one). May render it as a visible border
- Async API with concurrent implementation for faster test execution
- Produced `new.png`, `diff.png`, `merge.png` on test failure help to visually spot difference between expectation and actual render
- Accessibility snapshots to capture accessibility labels. May be handy during UIKit -> SwiftUI refactor, tests automatically ensures that UI hints still present

## Limitations

- `Xcode` version change may break some tests. Either color components may vary (without visible difference) or layer/text border may shift due to antialiasing algo changes. `iOS SDK` (bundled with `Xcode.app`) and `iOS Simulator Runtime` versions have impact on `UIKit` behavior
- `Xcode` version, `Simulator` device model and version should be fixed and frozen for your test scheme. `Xcode.app` update will usually  require you to commit breaking changes
- `Git LFS` is strongly advised as tool for .png references storage. Images are significantly larger than text files, storing them directly in commit history will explode repository size
- Animations have to be turned off to stabilize image capture result (use View model toggle). Otherwise test case will be unstable, captured animation frame may shift between test launches
- `Snapshot Testing` target should have iOS app specified as the `TEST_HOST`, otherwise `UIKit` render pipe won't work
- Therefore you need to pack test target code in `.xcodeproj`. Swift Packages currently do not allow us to declare iOS app targets
- `View` instance have to be uniq per each `prepareSut()` invocation inside assert method. Sequential View re-appearance may affect layout
- `SnapshotFiles` fails to locate files if project directory path contains spaces

## Usage

See [example repository](https://github.com/salute-developers/snapshots-kit-ios-sample) for sample project and test code.

## Alternatives

- [swift-snapshot-testing by PointFree](https://github.com/pointfreeco/swift-snapshot-testing)
  - ✅ Do not require Simulator Device launch and `TEST_HOST` app
  - ✅ Wider capabilities (may assert any objects equality)
  - ❌ Uses `CoreGraphics` rendering, `UIKit` views display is inaccurate (layer effects, borders, shadows, opacity may have visual artifacts)

## License

Package is under [MIT License](LICENSE).

## Thanks

- [Максим Кузнецов](https://github.com/maxibello) – initial library design
- [Бодров Александр](https://github.com/amidaleet) – `SwiftUI` support, respect of safe area, async API, concurrent Matcher, Matcher sensitivity calibration
- [Сергей Уразов](https://github.com/urazov-s) – accessibility testing
