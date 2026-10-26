# Kernel Driver Development and Hardware Safety Plan

## When kernel-level changes are justified

A kernel driver is appropriate only after evidence shows that:

1. the physical feature exists;
2. the firmware or device exposes a usable protocol;
3. the protocol is understood well enough to implement safely;
4. no existing driver already supports the exact hardware/firmware combination; and
5. the missing functionality cannot be resolved by configuration or an existing user-space interface.

A driver is not the first remedy for every missing control. A lack of `/sys/class/leds` endpoint may mean an existing driver is absent, the firmware has a proprietary interface, the feature is not present, or the capture is incomplete.

## Preferred architecture

1. **Discovery tools:** collect SMBIOS, PCI IDs, WMI metadata, ACPI table information, thermal-zone types and hwmon attributes.
2. **Kernel interface:** reuse an existing supported subsystem—such as LED class, hwmon, platform profile, or an appropriate platform/x86 interface—when possible.
3. **Driver:** implement only the protocol and functionality that the hardware evidence supports. Match narrowly against validated IDs and firmware behavior.
4. **User-space interface:** build a CLI/daemon/UI on top of the supported kernel interface. User-facing software should not issue arbitrary raw hardware writes.
5. **Packaging and lifecycle:** test against the exact kernel; document version compatibility, rollback and failure behavior; upstream the work if practical.

## Development stages

### Stage 1 — read-only reverse engineering

- Enumerate `/sys/bus/wmi/devices`, associated attributes and device metadata.
- Inspect DSDT and relevant SSDT tables.
- Search source code for exact GUIDs, ACPI names and PCI/subsystem identifiers.
- Keep an evidence log showing the method name, parameter format, return type, device match, observed effect and firmware version.

### Stage 2 — prototype only after protocol confirmation

- Prefer a test machine or a setup with a reliable recovery route.
- Do not begin with a broad root daemon or undocumented EC writes.
- Establish original values and a known-good recovery/reboot procedure.
- Test one non-destructive operation at a time.
- Preserve cooling and thermal protection paths.

### Stage 3 — kernel driver

For a WMI-backed driver, follow the current Linux WMI driver-development documentation. The current upstream guide favors the modern bus-based WMI driver API for new drivers and warns against bypassing the WMI subsystem. ACPI and WMI payloads are device-specific; method IDs and buffers must be grounded in actual firmware metadata, not copied blindly from a different model.

For fan sensors or controllers, use the hwmon subsystem when it matches the capability. For keyboard lighting, investigate the LED subsystem or existing platform backlight conventions, depending on the hardware interface and current kernel API. The right subsystem depends on what the protocol actually does.

### Stage 4 — test and maintain

- Build the module against the currently installed kernel first.
- Test probe, removal, shutdown, suspend/resume and failure cases.
- Make repeated device instances safe.
- Validate ranges and return errors cleanly.
- Avoid unsafe initialization assumptions or writes during probe unless they are required and proven safe.
- Use DKMS only if out-of-tree distribution and automatic rebuilds are required; remember that a kernel update can still break a module.
- Keep a recovery option such as a known-good boot entry and the ability to remove/blacklist a failed test module from another boot environment.

## Do not do these things during initial investigation

- Do not write arbitrary bytes to EC registers.
- Do not invoke guessed WMI/ACPI methods.
- Do not force-load a driver intended for a different laptop solely because the subsystem vendor mentions Clevo/KAPOK.
- Do not disable thermal safeguards, remove CPU thermal drivers, or force the fan off.
- Do not patch a production kernel before obtaining the exact source of the interface behavior.
- Do not expose raw privileged hardware commands directly to a desktop UI.

## Why root is not the solution by itself

Root changes permission boundaries; it does not create undocumented firmware methods, supply a missing protocol implementation, or make a device-specific driver compatible. The key work here is hardware identification and protocol evidence, followed by using the correct Linux kernel subsystem.

## References

- Linux WMI driver-development guide: <https://docs.kernel.org/wmi/driver-development-guide.html>
- Linux ACPI WMI interface: <https://docs.kernel.org/wmi/acpi-interface.html>
- Linux hwmon subsystem: <https://docs.kernel.org/hwmon/>
- Linux platform/x86 driver source: <https://github.com/torvalds/linux/tree/master/drivers/platform/x86>
