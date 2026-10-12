# Clean Mode

A small macOS menu bar utility that locks the keyboard and trackpad/mouse so you can wipe your MacBook without accidental key presses or cursor bumps.

## Requirements

- macOS 14 or later
- Xcode 15+ (to build)
- **Accessibility** permission (required for input locking)

## Open & build

```bash
cd /Users/emmiva/Code/personal/CleanMode
open CleanMode.xcodeproj
```

In Xcode: select the **Clean Mode** scheme → **My Mac** → Run (⌘R).

Or from the terminal:

```bash
xcodebuild -scheme CleanMode -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/CleanMode.app
```

## Grant Accessibility

1. Start Clean Mode once (menu bar droplet → **Start Clean Mode**).
2. macOS may show a trust prompt — allow it, or open **System Settings → Privacy & Security → Accessibility**.
3. Enable the checkbox for **Clean Mode**.
4. If the menu shows a warning triangle, choose **I’ve Granted Access** after enabling.

Unsigned/ad-hoc builds may need **right-click → Open** the first time (Gatekeeper).

## How to use

1. Click the **droplet** icon in the menu bar.
2. Choose **Start Clean Mode**.
3. A soft graphite overlay appears. Keyboard and pointer input are ignored.
4. Wipe freely.
5. **Hold Option (⌥) for 5 seconds** to exit. A progress bar appears while you hold.
6. The app stays in the menu bar for next time.

Auto-unlocks after **10 minutes**, and unlocks if the Mac sleeps, the app crashes, or you Force Quit (fail open).

## Safety

Clean Mode is a convenience for physical cleaning — not a kiosk lockdown. Prefer unlocking unexpectedly over leaving the Mac stuck locked.
