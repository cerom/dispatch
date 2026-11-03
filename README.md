# FaceKey — make a face, get the emoji

A native iOS app + custom keyboard. Pull a face at the front camera and FaceKey ranks the emojis that look most like your expression. Tap one to type it.

## How it works

```
┌──────────── FaceKey app ─────────────┐        App Group         ┌──── FaceKey keyboard ────┐
│ ARKit face tracking (TrueDepth)      │   (shared UserDefaults)  │ Face-match row on top     │
│ 52 blend shapes → 16 features        │ ───── top 12 emojis ───▶ │ Full emoji grid           │
│ EmojiMatcher ranks 61 face emojis    │                          │ 📷 button opens the app   │
└──────────────────────────────────────┘ ◀──── facekey://scan ─── └───────────────────────────┘
```

**Why the app does the scanning:** iOS doesn't let keyboard extensions use the camera. So the keyboard's face button opens the FaceKey app (`facekey://scan`), you pull a face, then tap **◀︎** in the top-left status bar to go back. The keyboard picks up the matches from the shared App Group within a second.

- `Shared/` — compiled into both targets
  - `FaceFeatures.swift` — 16 expression features (smile, wink, tongue out, brows up, pucker, …), each 0–1
  - `EmojiCatalog.swift` — 61 face emojis, each with a hand-tuned expression target
  - `EmojiMatcher.swift` — weighted RMS distance between your face and each target → ranked matches
  - `SharedStore.swift` — App Group storage (latest matches + recents)
- `App/` — SwiftUI app: live camera, top match overlay, tap-to-copy grid, feature readout, keyboard setup guide
- `Keyboard/` — `UIInputViewController` hosting a SwiftUI emoji keyboard
- `Tests/` — unit tests for the matcher

Tuning: blend-shape gains live in `App/FaceFeatures+ARKit.swift`, emoji targets in `Shared/EmojiCatalog.swift`.

## Build & run

Requirements: a Mac with Xcode 15+, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and an iPhone with Face ID (TrueDepth camera). Face tracking doesn't work in the Simulator.

```sh
brew install xcodegen
# edit project.yml: set BUNDLE_ID_BASE to your own reverse-DNS id and DEVELOPMENT_TEAM to your team id
xcodegen generate
open FaceKey.xcodeproj
```

Run the **FaceKey** scheme on your phone, then:

1. Settings → FaceKey → Keyboards → enable **FaceKey** and **Allow Full Access** (needed to read the shared matches).
2. In any text field, hold 🌐 and pick FaceKey.
3. Tap the face button, pull a face, tap ◀︎ to return, and tap an emoji.

Run tests with ⌘U (or `xcodebuild test -scheme FaceKey -destination 'platform=iOS Simulator,name=iPhone 16'`).

## Known limitations

- Opening the app from the keyboard has no public API; it uses a responder-chain call that works today but App Review could flag it, and a future iOS could break it.
- Requires a TrueDepth camera. A Vision-based fallback (2D landmarks) for older phones isn't built yet.
- An iMessage app extension *can* use the camera, so a later version could do live in-chat matching without leaving Messages.
