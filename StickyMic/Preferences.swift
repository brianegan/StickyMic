import Foundation
import ServiceManagement

class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let preferredDeviceUID = "preferredDeviceUID"
        static let hideMenuBarIcon = "hideMenuBarIcon"
    }

    private init() {}

    /// The UID of the preferred audio input device
    var preferredDeviceUID: String? {
        get {
            defaults.string(forKey: Keys.preferredDeviceUID)
        }
        set {
            if let value = newValue {
                defaults.set(value, forKey: Keys.preferredDeviceUID)
            } else {
                defaults.removeObject(forKey: Keys.preferredDeviceUID)
            }
        }
    }

    /// Whether to hide the menu bar icon
    var hideMenuBarIcon: Bool {
        get {
            defaults.bool(forKey: Keys.hideMenuBarIcon)
        }
        set {
            defaults.set(newValue, forKey: Keys.hideMenuBarIcon)
        }
    }

    /// Whether the app should launch at login
    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}
