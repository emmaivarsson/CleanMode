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

macOS often shows CleanMode as allowed even when the *running* build is still blocked (common after rebuilds). Do this exact sequence:

1. Prefer the Release app:  
   `/Users/emmiva/Code/personal/CleanMode/build/Build/Products/Release/CleanMode.app`  
   or a copy in **Applications**.
2. Open **System Settings → Privacy & Security → Accessibility**.
3. Find **CleanMode** and turn it **ON** (if it was already on, toggle OFF then ON).
4. Click the menu bar icon → **Quit & Relaunch** (or Quit, then open the app again).
5. Click **Start Clean Mode**.

If it still prompts: delete any duplicate CleanMode rows in Accessibility, re-add by launching Start once more, then Quit & Relaunch.

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
