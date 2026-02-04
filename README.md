# StickyMic

A macOS menu bar app that keeps your microphone "stuck" to your preferred input device. No more AirPods hijacking your mic during calls!

## Features

- **Stick to your preferred mic** - Select which audio input device should always be used
- **Automatic switching prevention** - When AirPods or other Bluetooth devices connect, the app automatically switches back to your preferred input
- **Menu bar app** - Lives quietly in your menu bar, no Dock icon
- **Launch at Login** - Optionally start the app when you log in
- **Hide menu bar icon** - Run completely in the background if desired

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for development)

## Installation

### From Release Build

1. Download `StickyMic.app` from the releases
2. Move it to `/Applications`
3. Launch the app
4. Click the microphone icon in the menu bar and select your preferred input device

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/sticky-mic.git
   cd sticky-mic/StickyMic
   ```

2. Build the release version:
   ```bash
   xcodebuild -project StickyMic.xcodeproj \
              -scheme StickyMic \
              -configuration Release \
              build
   ```

3. Copy to Applications:
   ```bash
   cp -R ~/Library/Developer/Xcode/DerivedData/StickyMic-*/Build/Products/Release/StickyMic.app /Applications/
   ```

4. Launch:
   ```bash
   open /Applications/StickyMic.app
   ```

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Command Line Tools: `xcode-select --install`

### Opening the Project

**Option 1: Xcode**
```bash
open StickyMic/StickyMic.xcodeproj
```

**Option 2: Command Line**
```bash
cd StickyMic
xcodebuild -project StickyMic.xcodeproj \
           -scheme StickyMic \
           -configuration Debug \
           build
```

### Running in Development

After building, run the debug build:
```bash
open ~/Library/Developer/Xcode/DerivedData/StickyMic-*/Build/Products/Debug/StickyMic.app
```

Or press `Cmd+R` in Xcode.

### Project Structure

```
StickyMic/
├── StickyMic.xcodeproj/           # Xcode project file
├── StickyMic/
│   ├── StickyMicApp.swift         # App entry point, menu bar setup
│   ├── AudioDeviceManager.swift   # CoreAudio device enumeration/control
│   ├── AudioDeviceMonitor.swift   # Listens for device changes
│   ├── Preferences.swift          # UserDefaults storage, login item
│   ├── MenuBarIcon.swift          # Custom menu bar icon drawing
│   ├── AppIconGenerator.swift     # Programmatic app icon generation
│   ├── Assets.xcassets/           # App icon assets
│   ├── Info.plist                 # App configuration
│   └── StickyMic.entitlements
└── GenerateIcons.swift            # Helper script for icon generation
```

### Key Components

| File | Purpose |
|------|---------|
| `AudioDeviceManager.swift` | Wraps CoreAudio APIs to list input devices and get/set the default input |
| `AudioDeviceMonitor.swift` | Uses CoreAudio property listeners to detect when devices change or the default input switches |
| `Preferences.swift` | Persists the preferred device UID and manages the "Launch at Login" setting via `SMAppService` |
| `MenuBarIcon.swift` | Draws the menu bar microphone icon programmatically as a template image |

### Regenerating App Icons

If you modify `AppIconGenerator.swift` and want to regenerate the app icons:

```bash
cd StickyMic
swift GenerateIcons.swift
```

This creates PNG files in `StickyMic/Assets.xcassets/AppIcon.appiconset/`.

## Usage

1. **Launch the app** - A microphone icon (with tape!) appears in the menu bar
2. **Select preferred device** - Click the icon and choose your preferred microphone (e.g., "MacBook Pro Microphone")
3. **Connect Bluetooth device** - When AirPods connect, macOS will try to switch, but StickyMic immediately switches back to your preferred device

### Menu Options

- **Preferred Input Device** - Header showing current mode
- **None (allow automatic)** - Disables protection, allows macOS to auto-switch
- **[Device names]** - Select your preferred input device (checkmark indicates selection)
- **Hide Menu Bar Icon** - Hides the icon; relaunch app to show it again
- **Launch at Login** - Start automatically when you log in
- **Quit** - Exit the application

## How It Works

The app uses CoreAudio's property listener system to monitor two events:

1. `kAudioHardwarePropertyDevices` - Fires when devices are added/removed
2. `kAudioHardwarePropertyDefaultInputDevice` - Fires when the default input changes

When the default input changes and a preferred device is set, the app checks if the preferred device is still available. If so, it immediately calls `AudioObjectSetPropertyData` to switch back.

## Troubleshooting

### App doesn't appear in menu bar
- Check if "Hide Menu Bar Icon" was previously enabled
- Relaunch the app from `/Applications` or Spotlight

### Input doesn't switch back
- Ensure a preferred device is selected (not "None")
- Verify the preferred device is connected and available
- Check System Settings > Privacy & Security > Microphone (app may need permission)

### Launch at Login doesn't work
- Go to System Settings > General > Login Items
- Ensure StickyMic is listed and enabled

## License

MIT License - See LICENSE file for details
