# Next Diagnostic Commands — Read-Only Collection

This is a staged checklist for collecting the missing evidence. Run commands in order and save their output. None of the commands below intentionally changes fan, lighting, thermal or power settings.

## 1. Confirm boot/session identity

```bash
uname -a
cat /etc/os-release
```

## 2. Map thermal zones

```bash
for d in /sys/class/thermal/thermal_zone*; do
    echo "=== $d ==="
    for f in type temp mode policy; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done
```

## 3. Map cooling devices

```bash
for d in /sys/class/thermal/cooling_device*; do
    echo "=== $d ==="
    for f in type cur_state max_state; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done
```

## 4. Enumerate hwmon attributes

```bash
for d in /sys/class/hwmon/hwmon*; do
    echo "=== $d ==="
    printf 'name: '; cat "$d/name" 2>/dev/null
    find "$d" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
 done
```

## 5. Inventory LEDs and backlights

```bash
find -L /sys/class/leds /sys/class/backlight -maxdepth 3 -type f -print 2>/dev/null
```

## 6. Inspect WMI devices and driver bindings

```bash
find /sys/bus/wmi/devices -maxdepth 4 -type f -print 2>/dev/null
for d in /sys/bus/wmi/devices/*; do
    [ -e "$d" ] || continue
    echo "=== $d ==="
    readlink -f "$d/driver" 2>/dev/null || true
    udevadm info --query=all --path="$d" 2>/dev/null | grep -E 'DEVPATH=|DRIVER=|MODALIAS=|PRODUCT=' || true
 done
command -v lswmi && lswmi -V
```

`lswmi` is optional; the last line runs it only if installed.

## 7. Capture relevant kernel messages

```bash
sudo journalctl -k -b | grep -Ei 'ACPI|WMI|EC|thermal|cooling|fan|hwmon|acer|clevo|tuxedo|intel_pstate|powercap'
```

A lack of matches does not establish that a capability is absent; it only means the current boot log did not match these keywords.

## 8. Inspect CPU and power interfaces

```bash
cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null
cat /sys/firmware/acpi/platform_profile 2>/dev/null
cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null
find /sys/class/powercap -maxdepth 5 -type f -print 2>/dev/null
grep . /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver 2>/dev/null | head -40
grep . /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | head -40
grep . /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null | head -40
```

## 9. ACPI table investigation (only after the basic collection)

If the `acpica` utilities are missing, install them using the distribution package manager:

```bash
sudo pacman -S --needed acpica
```

Dump the DSDT table in binary form from a temporary directory:

```bash
mkdir -p /tmp/acer-acpi-investigation
cd /tmp/acer-acpi-investigation
sudo acpidump -n DSDT -b
ls -lh *.dat
```

Use `iasl -d` on the actual file name created. For example, if the generated filename is `dsdt.dat`:

```bash
iasl -d dsdt.dat
grep -niE 'backlight|keyboard|kbd|fan|thermal|cool|profile|WMBB|ABBC0F6B|ABBC0F6C|ABBC0F6D' ./*.dsl
```

Check whether SSDT tables exist and may include relevant methods too. The exact filenames and output depend on the tool version.

## 10. Save the evidence cleanly

Collect outputs into text files and label the date, kernel version, and exact command used. Before sharing publicly, redact serial numbers, UUIDs, MAC addresses if privacy matters, and any other unique identifiers.

## Interpretation reminders

- Missing sysfs entries mean that the particular endpoint was not found, not necessarily that the hardware feature is impossible to control.
- `cooling_device*` does not mean physical fans; read each `type`.
- WMI GUIDs do not identify their functions by themselves.
- Read-only ACPI disassembly is a discovery step; it does not justify calling an unknown method.
- Do not test raw EC writes or force fan states during this diagnostic phase.
