# Linux Hardware Interface Inventory

## Source and approach

Based on `hwc.txt`. This file lists symlinks under selected `/sys/class` directories. It is a useful snapshot but is not a complete recursive audit of all driver attributes or all possible interfaces.

## Current interface summary

### `hwmon`

The output lists six entries:

- `hwmon0` → AC power supply
- `hwmon1` → virtual thermal zone 0
- `hwmon2` → battery `BAT0`
- `hwmon3` → NVMe device `nvme0`
- `hwmon4` → `coretemp.0`
- `hwmon5` → virtual thermal zone 6

The presence of a `hwmon` entry means a monitoring device or bridge is registered. It does not imply that a fan controller is present or that its controls are writable.

The provided listing does not show any `fan*_input` or `pwm*` attributes. However, the output enumerates directory symlinks rather than the files inside every `hwmon` directory, so it is too early to make a categorical statement that no such attribute exists anywhere.

### Thermal zones and cooling devices

The output lists:

- Thermal zones: `thermal_zone0` through `thermal_zone6` (7 entries)
- Cooling devices: `cooling_device0` through `cooling_device13` (14 entries)

These are thermal-framework objects, not human-readable proof of fan controls. Their `type`, `cur_state`, `max_state`, and related files must be read to understand what each object represents.

### LEDs

The output lists:

- `input4::capslock`
- `input4::numlock`
- `input4::scrolllock`
- `mmc0::`
- `phy0-led`

The three first entries are keyboard lock indicators. The other two are associated with the card reader and Wi-Fi device. No obvious `kbd_backlight`, `keyboard_backlight`, or similarly named keyboard-lighting entry appears in the supplied list.

**Conclusion:** keyboard-backlight control is not demonstrated through the listed standard LED interfaces. This could mean the firmware lacks such control, that a driver does not expose it, or that another interface is used. More evidence is required.

### Display backlight

The output lists `intel_backlight` under `/sys/class/backlight`. This is the standard display-panel backlight endpoint exposed by the active Intel graphics path. Display brightness is separate from keyboard lighting.

### WMI

Three WMI devices appear under the ACPI WMI bus:

- `ABBC0F6B-8EA1-11D1-00A0-C90629100000-1`
- `ABBC0F6C-8EA1-11D1-00A0-C90629100000-2`
- `ABBC0F6D-8EA1-11D1-00A0-C90629100000-0`

The suffixes reflect WMI device instances represented in sysfs. The identifiers indicate that the firmware describes WMI objects; they do not identify their functions without metadata, associated methods, or driver/source documentation.

## Recommended interface discovery

```bash
# Find controls in all currently listed hwmon directories.
for d in /sys/class/hwmon/hwmon*; do
    echo "=== $d ==="
    cat "$d/name" 2>/dev/null
    find "$d" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
 done

# Map each thermal-zone and cooling-device entry.
for d in /sys/class/thermal/thermal_zone*; do
    echo "=== $d ==="
    for f in type temp mode policy; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done

for d in /sys/class/thermal/cooling_device*; do
    echo "=== $d ==="
    for f in type cur_state max_state; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done

# Show every LED/backlight name that the kernel currently exposes.
find -L /sys/class/leds /sys/class/backlight -maxdepth 2 -type f \
  \( -name brightness -o -name max_brightness -o -name trigger -o -name actual_brightness \) \
  -print 2>/dev/null
```

All of the commands above are read-only. Do not write to these files until the semantics of the specific attribute are understood and the hardware safety implications are clear.

## Technical reference

Linux hwmon documentation: <https://docs.kernel.org/hwmon/>  
Linux ACPI WMI interface: <https://docs.kernel.org/wmi/acpi-interface.html>
