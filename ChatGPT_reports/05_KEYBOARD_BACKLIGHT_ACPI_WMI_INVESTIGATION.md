# Keyboard Backlight Investigation: ACPI and WMI

## Problem statement

The supplied `/sys/class/leds` listing contains keyboard lock indicators but no obvious keyboard-backlight device. The current diagnostic therefore does not demonstrate a standard Linux keyboard-backlight interface.

This is not enough to prove the hardware cannot be controlled. It only shows that the captured listing does not expose an obvious endpoint under the path checked.

## Relevant observed evidence

- System: Acer Aspire Lite AL15-52.
- BIOS vendor/version: Insyde `1.07.11iRAC`.
- Embedded-controller firmware revision: `7.5`.
- ACPI/WMI device parent: `PNP0C14:00`.
- Three WMI instances are visible with GUIDs beginning `ABBC0F6B`, `ABBC0F6C`, and `ABBC0F6D`.
- No obvious `kbd_backlight` endpoint appears under `/sys/class/leds` in the supplied list.

## Hypothesis to test

The keyboard-light control, if supported by the hardware and firmware, may be exposed through a vendor-specific ACPI/WMI method rather than a standard LED class device. This remains a hypothesis; the WMI identifiers alone do not establish a keyboard-light function.

## Investigation sequence

### 1. Confirm the physical feature and baseline behavior

Confirm whether the laptop keyboard has a backlight and whether the firmware's documented hotkey changes its state in the current OS. Record the exact key combination and any on-screen indication. This helps avoid reverse-engineering a feature absent from the physical configuration.

### 2. Enumerate all relevant Linux endpoints

```bash
find -L /sys/class/leds /sys/class/backlight -maxdepth 3 -type f -print 2>/dev/null
find /sys/bus/wmi/devices -maxdepth 3 -type f -print 2>/dev/null
```

Do not assume that every WMI method is directly callable from these files. WMI metadata and kernel drivers determine what is exposed.

### 3. Inspect WMI metadata

The upstream Linux WMI driver guide recommends obtaining detailed WMI information and inspecting the ACPI methods behind devices. If a compatible `lswmi` tool is already installed, use its documented verbose mode:

```bash
command -v lswmi && lswmi -V
```

If `lswmi` is unavailable, identify an appropriate package/source for the current distribution before installing anything. Capture the metadata for each of the three instances, including method IDs, instance counts, and associated ACPI paths where available.

### 4. Dump and decompile ACPI tables

Install `acpica` only if the required utilities are not already present:

```bash
sudo pacman -S --needed acpica
```

Then work from a temporary directory:

```bash
mkdir -p /tmp/acer-acpi-investigation
cd /tmp/acer-acpi-investigation
sudo acpidump -n DSDT -b
ls -lh *.dat
```

The exact output filename depends on the utility/build; use the filename that the previous command created. Decompile that file, for example:

```bash
iasl -d dsdt.dat
```

If the filename is different, substitute the actual name. SSDT tables may also contain relevant methods; inspect their availability and dump/decompile them separately where appropriate.

Search the resulting `.dsl` files for relevant terms and exact GUID fragments:

```bash
grep -niE 'backlight|keyboard|kbd|fan|thermal|cool|profile|WMBB|ABBC0F6B|ABBC0F6C|ABBC0F6D' ./*.dsl
```

A text match is only a clue. Inspect the surrounding method definition and call paths to learn the parameters, return values, side effects, and firmware assumptions.

### 5. Compare to existing drivers and upstream source

Search the Linux source tree and maintained driver projects for the exact GUIDs, model identifiers, method names, and supported firmware families. Do not treat a driver for a different model as compatible merely because it uses the same vendor name. Compare its exact match table, ACPI/WMI method behavior, EC assumptions, and firmware revision restrictions.

### 6. Decide what is required

- If an existing driver supports the device, test that driver's documented interfaces first.
- If a relevant method is present but unsupported, determine whether a small upstream-style kernel driver can expose it.
- If no corresponding firmware method exists, investigate alternate firmware paths or confirm that the feature is not controllable through Linux.

## Safety warnings

Do not invoke guessed ACPI/WMI methods or write arbitrary binary buffers. Do not write EC offsets or use an `acpi_call`-style workaround without first knowing the exact method semantics. A keyboard-light command can have unexpected side effects if the method or parameters are wrong.

## References

- Linux WMI driver development: <https://docs.kernel.org/wmi/driver-development-guide.html>
- Linux ACPI WMI interface: <https://docs.kernel.org/wmi/acpi-interface.html>
- Linux platform/x86 drivers: <https://github.com/torvalds/linux/tree/master/drivers/platform/x86>
