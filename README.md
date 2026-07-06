# Rat

Rat is a native macOS menu bar utility for mapping extra mouse buttons to Spaces/Desktop navigation shortcuts.

## Build

Open `Rat.xcodeproj` in Xcode, select the `Rat` scheme, and run the app.

If full Xcode is not available, build with Apple Command Line Tools:

```bash
cd /Users/fae/Documents/code/Rat
chmod +x scripts/build-release.sh scripts/install.sh
scripts/install.sh
```

Rat runs as a menu bar utility and keeps working while Settings is closed. Use the Rat menu bar item to open Settings, pause or resume the listener, toggle Launch at Login, or quit.

The build script generates the Rat app icon and menu bar icon into `Rat/Resources`.

## Permissions

Rat uses a listen-only `CGEventTap` to detect mouse buttons and asks System Events to run desktop navigation shortcuts. It needs Accessibility permission, Automation permission for System Events, and macOS may require Input Monitoring for button detection.

Open Settings > Permissions inside the app to request Accessibility permission or jump to the relevant System Settings panes.

## MVP Notes

- The settings window can be closed while the listener keeps running.
- Left and right clicks are shown in the tester but ignored for action execution.
- Button 2 and higher can be mapped.
- Show Desktop is present as a placeholder and does not run a shortcut yet.
- Launch at Login uses `SMAppService.mainApp`.
