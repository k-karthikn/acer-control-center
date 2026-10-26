# Analysis of your three hardware diagnostic files

Your files show that your Acer Aspire Lite AL15-52 has several Linux hardware interfaces available, but the standard Linux interfaces currently do not expose keyboard-backlight control or an obvious fan-speed control interface. The next step is to investigate the firmware-specific interfaces, not to obtain more root permissions.

## 1. `info.txt` — hardware, firmware and kernel

Laptop and firmware

Acer Aspire Lite AL15-52, Insyde BIOS version `1.07.11iRAC`, dated March 13, 2024. The reported embedded-controller firmware revision is `7.5`.

Operating system and kernel

CachyOS, kernel `7.2.11-1-cachyos`. Your kernel already includes numerous hardware drivers.

Processor and graphics

Intel Alder Lake-U15 platform with Intel UHD Graphics. The graphics driver is `i915`; the processor thermal device is using `proc_thermal_pci`.

Important hardware identification

Several Intel PCI devices report the subsystem vendor as `CLEVO/KAPOK`, ID `1558:4150`, despite the laptop being Acer-branded. This is a useful clue when investigating the platform's hardware-control implementation.

The kernel already has drivers for the Intel graphics, CPU thermal interface, Wi-Fi, NVMe storage, SMBus and other devices. So this is not a case where Linux has no hardware-level access at all.

However, the PCI subsystem identification alone does not prove that every Clevo-specific keyboard or fan driver will work on your laptop.

## 2. `hwc.txt` — which control interfaces Linux exposes

Your output gives us a useful picture of the current state.

| Interface                 | What your output shows                                                      |
| ------------------------- | --------------------------------------------------------------------------- |
| CPU sensors               | Available through `coretemp`                                                |
| Thermal zones             | Seven entries, `thermal_zone0` through `thermal_zone6`                      |
| Cooling devices           | Fourteen entries, `cooling_device0` through `cooling_device13`              |
| Laptop display brightness | Available through `intel_backlight`                                         |
| Keyboard LEDs             | Only Caps Lock, Num Lock and Scroll Lock among the keyboard-related entries |
| Fan-speed sensors         | No obvious fan-labelled `hwmon` device                                      |
| Keyboard backlight        | No `kbd_backlight` or equivalent keyboard LED entry                         |
| ACPI/WMI                  | Three WMI device instances are present                                      |

The distinction that matters is between detecting a device and being able to control it. For example, thermal cooling devices can exist without exposing a user-adjustable fan-speed setting.

The three WMI identifiers are particularly interesting:

```
ABBC0F6B-8EA1-11D1-00A0-C90629100000-1
ABBC0F6C-8EA1-11D1-00A0-C90629100000-2
ABBC0F6D-8EA1-11D1-00A0-C90629100000-0
```

These identifiers are associated with ACPI/WMI interfaces used by some hardware platforms, including Clevo-related implementations. Their presence is a lead for further investigation, but it does not prove that these interfaces expose your keyboard lighting or fan controls.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://github.com\&sz=32)

GitHub

+1



## 3. `senpowman.txt` — sensors and power management

Your sensor readings are from a relatively cool system at the time of capture.

| Measurement          | Reported value |
| -------------------- | -------------- |
| CPU package          | 34–35°C        |
| Individual CPU cores | 29–34°C        |
| ACPI thermal zone    | 41°C           |
| Wi-Fi                | 37°C           |
| NVMe SSD             | 33.9°C         |
| Battery voltage      | 11.40–11.45 V  |
| Battery current      | 416–531 mA     |

The file also reports `intel_pstate` as `active`. That means the Intel P-state CPU performance-scaling driver is active; it does not mean that every CPU power limit or firmware setting is user-adjustable.&#x20;

senpowman.txt



The readings do not tell us your fan RPM, CPU package power consumption, or actual power limits. They are sensor snapshots, not a stress test.

## 4. What this means for your hardware-control project

I would split your investigation into three tracks.

Track A — Keyboard backlight

There is a promising lead: the Clevo/Santech Linux backlight project documents a `WMBB` ACPI method associated with the `ABBC0F6D` WMI GUID found in your output. But that implementation was tested on a different laptop. We still need to verify that your own firmware contains the required method before attempting any hardware write.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://github.com\&sz=32)

GitHub



Track B — Fan control

Identify what your 14 cooling devices actually represent. A Linux thermal driver might control CPU throttling rather than fan speed. We need to establish whether fan control is available through Acer WMI, another firmware method, or the embedded controller.

Track C — CPU power and performance

Your Intel P-state driver and processor thermal driver are already active. Next, inspect the exposed CPU frequency, energy-performance preference, package power limits, and platform-profile interfaces before writing a custom driver.

## 5. The next diagnostic commands

Run these read-only commands first. They will help us distinguish existing functionality from a missing driver.

A. Find platform-specific devices and loaded modules

```
printf '%s\n' '--- Platform devices ---'
ls /sys/devices/platform/ |
  grep -Ei 'clv|clevo|tuxedo|acer|wmi|ec' || true

printf '%s\n' '--- Relevant kernel modules ---'
lsmod |
  grep -Ei 'acer_wmi|clevo|tuxedo|acpi_call|ec_sys|intel_pstate' || true
```

B. Map the cooling devices and available fan controls

```
for d in /sys/class/thermal/cooling_device*; do
    printf '\n%s\n' "$d"
    printf 'type: '
    cat "$d/type" 2>/dev/null
    printf 'current state: '
    cat "$d/cur_state" 2>/dev/null
    printf 'maximum state: '
    cat "$d/max_state" 2>/dev/null
done

for d in /sys/class/hwmon/hwmon*; do
    printf '\n%s: ' "$d"
    cat "$d/name" 2>/dev/null
    find "$d" -maxdepth 1 -type f \
      \( -name 'fan*_input' -o -name 'pwm*' \) -print
done
```

C. Check the firmware method before attempting keyboard-backlight control

If the ACPI tools are not already installed:

```
sudo pacman -S --needed acpica
```

Then extract and decompile the DSDT firmware table:

```
sudo acpidump -n DSDT -b -o /tmp/dsdt.dat
iasl -d /tmp/dsdt.dat
grep -niE 'WMBB|ZEVT|BACKLIGHT|KEYBOARD' /tmp/dsdt.dsl
```

We are looking for evidence that the firmware implements the `WMBB` method and the relevant keyboard-light operation. A match would give us a stronger basis for investigating the documented Clevo approach; no match means we should investigate other ACPI/WMI methods instead.

Do not enable arbitrary embedded-controller writes or force-load a patched vendor driver yet. The current output is enough to identify a promising route, but not enough to establish that a particular register or method is safe for your exact firmware.

One additional privacy point: `info.txt` contains your machine's serial number and UUID. Redact those fields before posting the report publicly.

The correct next move is to map the cooling devices and verify the firmware method. That will tell us whether the missing controls can be exposed with an existing driver, require a small kernel-driver change, or need deeper firmware reverse engineering.
