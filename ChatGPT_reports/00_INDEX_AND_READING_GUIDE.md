# Acer Aspire Lite AL15-52 — Linux Hardware Control Investigation

**Report set:** 19 October 2026  
**System reported:** CachyOS, x86_64, kernel `7.2.11-1-cachyos`  
**Evidence provided:** `info.txt`, `hwc.txt`, `senpowman.txt`

## Purpose

This set organizes the supplied system diagnostics into separate reports to help investigate Linux system, firmware, kernel, and hardware controls—especially keyboard backlight, fan control, thermal management, and CPU power settings.

The reports distinguish three categories:

- **Observed:** directly printed by the supplied command output.
- **Interpretation:** a cautious explanation of what the output implies.
- **Unconfirmed:** a question that requires more evidence or a controlled test.

No hardware registers or firmware methods were written to during this analysis. Device serial number and system UUID have been omitted from these reports for privacy.

## Files in this report set

1. [`01_EXECUTIVE_FINDINGS.md`](01_EXECUTIVE_FINDINGS.md) — key conclusions and priorities.
2. [`02_HARDWARE_FIRMWARE_INVENTORY.md`](02_HARDWARE_FIRMWARE_INVENTORY.md) — machine identity, firmware and PCI devices.
3. [`03_LINUX_INTERFACE_INVENTORY.md`](03_LINUX_INTERFACE_INVENTORY.md) — current sysfs, hwmon, thermal, LED, backlight and WMI exposure.
4. [`04_SENSOR_THERMAL_POWER_ANALYSIS.md`](04_SENSOR_THERMAL_POWER_ANALYSIS.md) — temperatures, battery readings, and limits of the snapshot.
5. [`05_KEYBOARD_BACKLIGHT_ACPI_WMI_INVESTIGATION.md`](05_KEYBOARD_BACKLIGHT_ACPI_WMI_INVESTIGATION.md) — safe plan for investigating firmware-specific lighting controls.
6. [`06_FAN_AND_THERMAL_CONTROL_INVESTIGATION.md`](06_FAN_AND_THERMAL_CONTROL_INVESTIGATION.md) — identify what cooling devices do and whether fan control is exposed.
7. [`07_CPU_POWER_AND_PERFORMANCE_CONTROLS.md`](07_CPU_POWER_AND_PERFORMANCE_CONTROLS.md) — inspect CPU scaling, platform profile, and power-limit interfaces.
8. [`08_KERNEL_DRIVER_DEVELOPMENT_AND_SAFETY.md`](08_KERNEL_DRIVER_DEVELOPMENT_AND_SAFETY.md) — when a driver is needed and how to approach it safely.
9. [`09_NEXT_DIAGNOSTIC_COMMANDS.md`](09_NEXT_DIAGNOSTIC_COMMANDS.md) — consolidated copy-and-run read-only command plan.
10. [`10_KEYBOARD_BACKLIGHT_FIX_REPORT.md`](10_KEYBOARD_BACKLIGHT_FIX_REPORT.md) — the tested keyboard-backlight fix completed on 26 October 2026, including commands, installed files, and verification.

## Main conclusion

Linux already recognizes and drives many components in this machine. The uploaded output does **not** show a standard keyboard-backlight LED interface or an obvious fan RPM/PWM interface. This makes firmware-interface investigation reasonable, but it does not yet prove that a custom driver is required—or that any particular Clevo/Acer control method is compatible.

The most useful next step is to map the existing thermal devices, collect detailed information about the three WMI instances, and inspect the ACPI tables for relevant methods. Do not begin with arbitrary embedded-controller writes.

**26 October 2026 update:** The keyboard-backlight investigation continued with the user's approval. The ACPI table revealed a white-light control, and controlled tests confirmed it works. See the [keyboard-backlight fix report](10_KEYBOARD_BACKLIGHT_FIX_REPORT.md) for the exact method, installed script, and test results. The earlier read-only statement above applies to the 19 October report set, before this follow-up.

## General technical references

These are upstream documentation references for the interfaces discussed; they are not proof of the exact firmware behavior of this laptop.

- Linux WMI driver development guide: <https://docs.kernel.org/wmi/driver-development-guide.html>
- Linux ACPI WMI interface: <https://docs.kernel.org/wmi/acpi-interface.html>
- Linux hardware-monitoring (hwmon) subsystem: <https://docs.kernel.org/hwmon/>
- Linux platform/x86 driver source tree: <https://github.com/torvalds/linux/tree/master/drivers/platform/x86>

## Important safety boundary

Read-only inventory and ACPI table inspection are the appropriate first steps. Do not write unknown values to `/sys`, invoke guessed WMI methods, use undocumented EC register offsets, or disable thermal protections. Those actions can destabilize the system or interfere with cooling and power behavior.
