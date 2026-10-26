# Fan and Thermal Control Investigation

## Current evidence

The uploaded data shows:

- `proc_thermal_pci` bound to the Intel processor thermal device at PCI `00:04.0`;
- seven thermal-zone symlinks under `/sys/class/thermal`;
- fourteen cooling-device symlinks under `/sys/class/thermal`;
- hwmon entries for AC power, a thermal zone, battery, NVMe, CPU core temperatures, and another thermal zone;
- no fan RPM values in the `sensors` output;
- no explicit fan-labelled or PWM control path shown by the supplied high-level listing.

The last item does not prove that a physical fan cannot be controlled. The listing does not display every file under every hwmon directory or identify the meaning of every thermal/cooling entry.

## Key distinction

Linux thermal framework devices and physical fan controllers are not interchangeable concepts.

- A thermal zone reports temperature and may participate in thermal policy.
- A cooling device provides a framework-specific cooling state.
- A fan tachometer interface normally reports an RPM-like value, often via a `fan*_input` attribute.
- A programmable fan controller may expose PWM-related attributes, but firmware can keep control fully automatic or expose a proprietary method instead.

Therefore, fourteen cooling devices do not mean that fourteen fans exist or that fan speed is user-adjustable.

## Step 1: map thermal zones

```bash
for d in /sys/class/thermal/thermal_zone*; do
    echo "=== $d ==="
    for f in type temp mode policy; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done
```

Where available, inspect each zone's `trip_point_*_type` and `trip_point_*_temp` files read-only. These can reveal thresholds, but they should not be changed during discovery.

## Step 2: map cooling devices

```bash
for d in /sys/class/thermal/cooling_device*; do
    echo "=== $d ==="
    for f in type cur_state max_state; do
        [ -r "$d/$f" ] && printf '%s: %s\n' "$f" "$(cat "$d/$f")"
    done
 done
```

A device type such as a processor or Intel-specific cooling mechanism suggests the framework endpoint is not a direct fan RPM interface. Confirm using kernel logs and driver source rather than guessing based on the type string alone.

## Step 3: enumerate every hwmon file

```bash
for d in /sys/class/hwmon/hwmon*; do
    echo "=== $d ==="
    printf 'name: '; cat "$d/name" 2>/dev/null
    find "$d" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
 done
```

Look for `fan*_input`, `fan*_label`, `pwm*`, or vendor-specific attributes. Presence of a file does not automatically mean it should be written to. Check the documented semantics and permissions first.

## Step 4: inspect relevant logs and drivers

```bash
sudo journalctl -k -b | grep -Ei 'thermal|cooling|fan|hwmon|ACPI|WMI|EC|acer|clevo|tuxedo'
lsmod | grep -Ei 'acer_wmi|clevo|tuxedo|thinkpad_acpi|dell_smm|wmi|hwmon'
```

The list of loaded modules is a discovery aid, not an instruction to force-load unrelated vendor drivers.

## Step 5: look for firmware control paths

Use the WMI/ACPI method in the companion keyboard-backlight report. Determine whether firmware describes a fan mode, performance profile, or EC method. Search only after identifying exact method names and platform matching; never send arbitrary values to an unknown method.

## Safety boundaries

- Preserve BIOS/firmware thermal safeguards.
- Do not disable thermal zones or unload required thermal drivers to test fan behavior.
- Do not force a fan to stop or force an unverified speed during CPU load.
- Do not write `cur_state`, `pwm*`, or EC values until the interface and permitted range are confirmed.
- A BIOS-controlled fan with no user endpoint may still be operating correctly under firmware control.

## Desired outcome

The initial goal is an evidence-backed answer to one of these questions: (a) a supported fan-control interface already exists, (b) Linux exposes only thermal/throttling interfaces and firmware manages the fan, (c) a known vendor protocol needs a compatible driver, or (d) the method remains unknown and needs deeper reverse-engineering. Do not jump directly to a custom fan-control daemon before resolving this.
