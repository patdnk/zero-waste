# App Store assets

| Path | What it is |
|---|---|
| `app-icon-1024.png` | Marketing icon (opaque, no alpha), same as the app's default icon |
| `screenshots/6.9in/` | 1320 × 2868 panels for 6.9" iPhones (required by App Store Connect) |
| `screenshots/6.5in/` | 1284 × 2778 panels for 6.5" iPhones |
| `screenshots/overview.png` | All 6.9" panels side by side, for review only (don't upload) |
| `metadata/en-GB/` | Name, subtitle, keywords, description, promo text, release notes (fastlane `deliver` layout) |
| `raw/` | Unframed simulator captures the panels are built from |

## Regenerating

Icons and panels are rendered from `ZeroBite/UI/BrandMark.swift`, the same view the app draws,
so the logo can't drift between the app and the store.

```bash
scripts/fetch-fonts.sh              # Mona Sans, needed for the app and the panel headlines
scripts/render-assets.sh icons      # AppIcon light / dark / tinted → Assets.xcassets
scripts/render-assets.sh marketing  # panels → appstore/screenshots
```

Panel copy, colours and pop-out crops are in `design/Marketing.swift`.

## Updating the raw captures

1. Boot the **iPhone 17 Pro Max** simulator, delete the app, install a fresh build, and set the status bar:
   `xcrun simctl status_bar booted override --time 9:41 --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4`
2. Skip onboarding, load **Try it with sample food**, dismiss the reminders tip and mark the Greek yogurt as used,
   so Spinach (due today) is the "Use first" item.
3. Save full-resolution captures with `xcrun simctl io booted screenshot appstore/raw/<name>.png`:
   `fridge`, `item-detail` (Spinach), `recipes`, `recipe-detail` (top recipe), `add-food` (scan sheet),
   `onboarding-scan` (Settings → How Zero Bite works → page 2).
4. If a screen's layout changed, update the `popOut` crop rectangles in `design/Marketing.swift`.

The live camera option doesn't exist on the simulator, so the Add food capture shows only the photo and
manual options; on a device "Scan with the camera" appears first.
