import SwiftUI
import AppKit

@main
struct StickyMicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let audioDeviceManager = AudioDeviceManager()
    private let audioDeviceMonitor = AudioDeviceMonitor()
    private let preferences = Preferences.shared

    /// Track if this is a relaunch to show icon temporarily
    private var showIconTemporarily = false

    /// Track known device UIDs to detect new device connections
    private var knownDeviceUIDs: Set<String> = []

    /// Track recently added devices (within a short time window)
    private var recentlyAddedDeviceUIDs: Set<String> = []

    /// Work item for clearing recently added devices
    private var clearRecentDevicesWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Generate app icon on first launch
        generateAppIconIfNeeded()

        // If the icon should be hidden but app was relaunched, show temporarily
        if preferences.hideMenuBarIcon {
            showIconTemporarily = true
        }

        // Initialize known devices before setting up monitoring
        knownDeviceUIDs = Set(audioDeviceManager.getInputDevices().map { $0.uid })

        setupStatusItem()
        setupAudioMonitoring()
    }

    /// Handle reopen (clicking dock icon or relaunching)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show the menu bar icon when app is relaunched
        if statusItem == nil {
            showIconTemporarily = true
            setupStatusItem()
        }
        return false
    }

    private func generateAppIconIfNeeded() {
        let assetsPath = Bundle.main.resourcePath ?? ""
        let iconPath = "\(assetsPath)/Assets.xcassets"

        // Only generate if running in debug/development
        #if DEBUG
        let projectPath = "/Users/brianegan/lab/bluetooth-mic-switcher/StickyMic/StickyMic/Assets.xcassets"
        if FileManager.default.fileExists(atPath: projectPath) == false {
            AppIconGenerator.generateAssetCatalog(at: projectPath)
        }
        #endif
    }

    private func setupStatusItem() {
        // Don't show if hidden (unless temporarily showing)
        if preferences.hideMenuBarIcon && !showIconTemporarily {
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = MenuBarIcon.create()
            button.image?.isTemplate = true
        }

        updateMenu()
    }

    private func hideStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func setupAudioMonitoring() {
        audioDeviceMonitor.onDefaultInputChanged = { [weak self] newDeviceID in
            guard let self = self else { return }

            // Get the UID of the new default device
            let currentDevices = self.audioDeviceManager.getInputDevices()
            let newDeviceUID = currentDevices.first(where: { $0.id == newDeviceID })?.uid

            // Only switch back if:
            // 1. We have a preferred device set
            // 2. The new device is different from our preferred device
            // 3. The new device was RECENTLY ADDED (not a manual user selection)
            if let preferredUID = self.preferences.preferredDeviceUID,
               let newUID = newDeviceUID,
               newUID != preferredUID,
               self.recentlyAddedDeviceUIDs.contains(newUID) {
                // A newly connected device took over - switch back to preferred
                if let preferredDevice = currentDevices.first(where: { $0.uid == preferredUID }) {
                    self.audioDeviceManager.setDefaultInputDevice(preferredDevice.id)
                }
            }

            DispatchQueue.main.async {
                self.updateMenu()
            }
        }

        audioDeviceMonitor.onDevicesChanged = { [weak self] in
            guard let self = self else { return }

            // Get current device UIDs
            let currentDeviceUIDs = Set(self.audioDeviceManager.getInputDevices().map { $0.uid })

            // Find newly added devices
            let addedDevices = currentDeviceUIDs.subtracting(self.knownDeviceUIDs)

            if !addedDevices.isEmpty {
                // Track recently added devices
                self.recentlyAddedDeviceUIDs.formUnion(addedDevices)

                // Clear the recently added devices after a short delay
                // This window allows us to detect automatic switches vs manual ones
                self.clearRecentDevicesWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.recentlyAddedDeviceUIDs.removeAll()
                }
                self.clearRecentDevicesWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
            }

            // Update known devices
            self.knownDeviceUIDs = currentDeviceUIDs

            DispatchQueue.main.async {
                self.updateMenu()
            }
        }

        audioDeviceMonitor.startMonitoring()
    }

    private func updateMenu() {
        guard let statusItem = statusItem else { return }

        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "Preferred Input Device", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // "None" option for automatic switching
        let noneItem = NSMenuItem(title: "None (allow automatic)", action: #selector(selectNone), keyEquivalent: "")
        noneItem.target = self
        if preferences.preferredDeviceUID == nil {
            noneItem.state = .on
        }
        menu.addItem(noneItem)

        menu.addItem(NSMenuItem.separator())

        // List all input devices
        let devices = audioDeviceManager.getInputDevices()
        let currentDefaultID = audioDeviceManager.getDefaultInputDeviceID()

        for device in devices {
            let item = NSMenuItem(title: device.name, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = device

            // Checkmark for preferred device
            if device.uid == preferences.preferredDeviceUID {
                item.state = .on
            }

            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Hide Menu Bar Icon action
        let hideIconItem = NSMenuItem(title: "Hide Menu Bar Icon", action: #selector(hideIcon), keyEquivalent: "")
        hideIconItem.target = self
        menu.addItem(hideIconItem)

        // Launch at Login toggle
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = preferences.launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func selectNone() {
        preferences.preferredDeviceUID = nil
        updateMenu()
    }

    @objc private func selectDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }

        preferences.preferredDeviceUID = device.uid
        audioDeviceManager.setDefaultInputDevice(device.id)
        updateMenu()
    }

    @objc private func hideIcon() {
        let alert = NSAlert()
        alert.messageText = "Hide Menu Bar Icon?"
        alert.informativeText = "The app will continue running in the background. To show the icon again, relaunch the app from Finder or Spotlight."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            preferences.hideMenuBarIcon = true
            showIconTemporarily = false
            hideStatusItem()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        preferences.launchAtLogin.toggle()
        updateMenu()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
