# Executive Findings — Acer Aspire Lite AL15-52

## Scope

This report interprets the three user-supplied diagnostic outputs. It describes the evidence that exists now and identifies the missing evidence needed to safely pursue deeper hardware control.

## Findings at a glance

| Area | Observed evidence | Current assessment | Confidence |
|---|---|---|---|
| Machine | Acer Aspire Lite AL15-52 | Model identified by SMBIOS | High |
| Firmware | Insyde `1.07.11iRAC`, 13 March 2024; EC revision `7.5` | ACPI and UEFI are reported supported | High for reported fields |
| Kernel | `7.2.11-1-cachyos` | The output describes a particular boot/session; re-check before future testing | High |
| CPU/GPU | Intel Alder Lake-U15 family; Intel UHD `i915` | Standard CPU and graphics drivers are bound | High |
| Thermal driver | `proc_thermal_pci` | Intel processor thermal device has a driver bound | High |
| CPU sensors | `coretemp` readings around 29–35°C | CPU temperature readings are exposed | High for snapshot |
| Thermal zones | `thermal_zone0` through `thermal_zone6` | Seven thermal-zone symlinks are present | High |
| Cooling devices | `cooling_device0` through `cooling_device13` | Fourteen cooling-device entries exist; their meanings are unknown from the supplied listing | High for count, low for function |
| Keyboard lighting | LEDs listed for Caps Lock, Num Lock, Scroll Lock, MMC and Wi-Fi; no obvious keyboard-backlight device | Standard keyboard-backlight control was not visible in this listing | Moderate; more discovery needed |
| Fan control | No obvious `fan*_input` or `pwm*` file shown in the inventory | Fan RPM/control is not demonstrated by these files | Moderate; diagnostic did not enumerate all files recursively |
| WMI | Three entries under `PNP0C14:00` with GUIDs beginning `ABBC0F6B`, `ABBC0F6C`, `ABBC0F6D` | Worth investigating, but purpose is not established | High for presence, unknown for capability |
| Display brightness | `intel_backlight` | Panel brightness interface exists | High |
| CPU power | `intel_pstate/status` output is `active` | Intel P-state scaling is active in the captured environment | High for snapshot |

## What the evidence does and does not prove

### Supported by the files

- This is an Acer-branded laptop whose SMBIOS product name is `Aspire Lite AL15-52`.
- The firmware vendor is listed as Insyde, with the BIOS and embedded-controller revision values shown above.
- The kernel has bound normal Linux drivers to the CPU thermal device, graphics, Wi-Fi, NVMe and several chipset components.
- Linux exposes temperature readings and thermal/cooling framework entries.
- Three WMI devices are listed under the ACPI WMI bus.
- The reported `/sys/class/leds` listing does not include an obvious keyboard-backlight endpoint.
- The supplied `sensors` output does not report fan RPM.

### Not established yet

- Whether the laptop physically has a keyboard backlight, or which lighting modes its firmware supports.
- Whether the three WMI devices expose keyboard lighting, fan modes, power profiles, or unrelated functions.
- Whether any cooling device is a fan, a processor throttle, or another cooling-framework endpoint.
- Whether a fan is operating at a particular RPM; no RPM value appears in the supplied output.
- Which CPU package power limits are configured or writable.
- Whether a custom kernel driver is required. A missing high-level endpoint can be caused by firmware design, an unbound driver, a disabled firmware feature, or a diagnostic listing that did not show the relevant path.

## Recommended priority order

1. **Inventory thermal and cooling device names.** Read each device's `type`, `cur_state` and `max_state`; do not change them.
2. **Inspect WMI metadata.** Check whether `lswmi` or equivalent tooling can identify each WMI instance and its associated ACPI methods.
3. **Inspect ACPI tables.** Disassemble the DSDT/SSDT tables and search for keyboard/backlight/fan/profile methods and the three WMI GUIDs.
4. **Inspect CPU power interfaces.** Discover available P-state, powercap, and platform-profile paths without writing to them.
5. **Only then choose an implementation path.** Prefer an existing in-kernel driver; write a driver only when there is a well-understood protocol and a demonstrated gap.

## Bottom line

The current blocker is not simply insufficient permissions. The unresolved question is which firmware interface, if any, controls the missing hardware functions and whether a compatible Linux driver already exists. The supplied files are useful first-pass evidence, not enough to justify low-level writes.
