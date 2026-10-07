# Zero Bite

An iOS app that catalogues what's in your fridge, freezer and cupboard, reminds you before
food expires, and ranks recipes by what you can cook right now — expiring items first.

## Features

- **Scan labels** — live camera scanning (VisionKit) reads best-before / use-by dates and
  barcodes; on the simulator, pick a photo of the label instead (Vision OCR).
- **Barcode lookup** — product name and category from Open Food Facts (no API key).
- **Expiry parsing** — UK/EU date formats (`12/09/26`, `12 SEP 2026`, `BEST BEFORE END OCT 2026`,
  `EXP 120926`…), keyword-aware so "use by" beats "packed on".
- **Reminders** — local notifications a few days before, on the day, and after expiry.
  Re-planned automatically whenever the fridge changes.
- **Recipes** — 35 bundled recipes matched against your inventory with synonym-aware
  ingredient matching (cheddar ≈ cheese, red pepper ≈ bell pepper) and store-cupboard staples.
  "I cooked this" marks the used items as consumed.

## Architecture

MVVM-C, mirroring `drivvy-ios`:

| Layer | Where | Notes |
|---|---|---|
| Flow state machine | `Coordination/AppFlowController` | `launch → welcome → main` |
| App coordinator | `Coordination/AppCoordinator` | tabs, sheets, alerts, deep links |
| Feature coordinators | `InventoryCoordinator`, `RecipesCoordinator`, `ScanCoordinator`, `SettingsCoordinator` | own `NavigationPath` + route enums |
| Factories | `Screens/*/…Factory.swift` | build view model + view; `ViewModelHost` keeps VMs alive |
| View models | `@MainActor @Observable`, dependencies injected | explicit state enums (`ScanFlowViewModel.Phase`, `ItemDetailViewModel.State`…) |
| Services | `Services/` | `InventoryStore` (SwiftData), `ExpiryDateParser`, `RecipeMatcher`, `ExpiryNotificationPlanner`, `OpenFoodFactsLookup` |

Everything that matters is pure and unit-tested: date parsing, name guessing, recipe
matching, notification planning, the store, and the view models (Swift Testing).

## Getting started

Requires Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
xcodegen generate
open ZeroBite.xcodeproj
```

Run the `ZeroBite` scheme on an iPhone simulator. Launch argument `--sample-data` fills an
empty fridge. Run tests with ⌘U or:

```bash
xcodebuild test -project ZeroBite.xcodeproj -scheme ZeroBite -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Typeface

The app is set in [Mona Sans](https://github.com/github/mona-sans) (SIL OFL). The font file
isn't committed; fetch it once and the project picks it up (falls back to the system font
when it's missing):

```bash
scripts/fetch-fonts.sh
```
