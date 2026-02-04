import Foundation
import CoreAudio

class AudioDeviceMonitor {

    var onDefaultInputChanged: ((AudioDeviceID) -> Void)?
    var onDevicesChanged: (() -> Void)?

    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Monitor for default input device changes
        var defaultInputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultInputAddress,
            defaultInputChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        // Monitor for device list changes
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            devicesChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        var defaultInputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultInputAddress,
            defaultInputChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )

        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            devicesChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    deinit {
        stopMonitoring()
    }
}

// MARK: - CoreAudio Callbacks

private func defaultInputChangedCallback(
    objectID: AudioObjectID,
    numberAddresses: UInt32,
    addresses: UnsafePointer<AudioObjectPropertyAddress>,
    clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = clientData else { return noErr }

    let monitor = Unmanaged<AudioDeviceMonitor>.fromOpaque(clientData).takeUnretainedValue()

    // Get the new default input device ID
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    var deviceID: AudioDeviceID = 0
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

    let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &dataSize,
        &deviceID
    )

    if status == noErr {
        monitor.onDefaultInputChanged?(deviceID)
    }

    return noErr
}

private func devicesChangedCallback(
    objectID: AudioObjectID,
    numberAddresses: UInt32,
    addresses: UnsafePointer<AudioObjectPropertyAddress>,
    clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = clientData else { return noErr }

    let monitor = Unmanaged<AudioDeviceMonitor>.fromOpaque(clientData).takeUnretainedValue()
    monitor.onDevicesChanged?()

    return noErr
}
