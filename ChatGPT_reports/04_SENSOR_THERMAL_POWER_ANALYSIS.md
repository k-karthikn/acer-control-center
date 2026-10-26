# Sensor, Thermal, and Battery Power Analysis

## Source

Based on `senpowman.txt`. It contains two `sensors` snapshots. Values varied slightly between the captures.

## Recorded measurements

| Sensor | Snapshot value(s) | Notes |
|---|---:|---|
| CPU package | 34–35°C | From `coretemp-isa-0000` |
| CPU cores shown | 29–34°C | Only selected core labels are printed by the sensor driver in this output |
| ACPI thermal zone | 41°C | `acpitz-acpi-0`, `temp1` |
| Wi-Fi | 37°C | `iwlwifi_1-virtual-0`, `temp1` |
| NVMe composite | 33.9°C | `nvme-pci-0100`, composite sensor |
| Battery voltage | 11.40–11.45 V | `BAT0-acpi-0`, `in0` |
| Battery current | 416–531 mA | `BAT0-acpi-0`, `curr1` |

The NVMe sensor output includes implausible low/high bounds for `Sensor 1` (`-273.1°C` and `65261.8°C`) while the reported current reading is 33.9°C. Treat those bounds as driver/device metadata or unsupported limits, not as real operating temperature observations.

## Interpretation

- These readings depict a fairly cool moment in the system, not a thermal load test.
- CPU temperature values do not reveal fan RPM or whether the fan curve is user-configurable.
- A temperature measured through ACPI does not necessarily identify the physical component without further ACPI/thermal-zone mapping.
- Battery voltage and current do not alone show battery health, capacity, charging state, or power draw of the laptop as a whole. The captured current sign/meaning depends on the reporting convention of the driver.
- The `intel_pstate` status printed as `active` means that the Intel P-state driver reports itself active in this captured environment. It does not expose current CPU power limits in the supplied output.

## Missing measurements needed for power analysis

The input files do not establish:

- fan speed in RPM;
- CPU package power in watts under load;
- sustained and short-duration CPU power limits;
- CPU frequency behavior during a build;
- thermal throttling events or reasons;
- battery design capacity, full-charge capacity, state of charge, or discharge rate under a controlled workload;
- whether a platform profile or vendor fan mode is available.

## Suggested next observations

For a baseline, capture temperatures and CPU frequency at idle, under a reproducible workload, and after returning to idle. Record the workload and time for each capture. Avoid changing fan-controller settings during this baseline.

```bash
sensors
cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null
cat /sys/firmware/acpi/platform_profile 2>/dev/null
find /sys/class/powercap -maxdepth 4 -type f -print 2>/dev/null
```

List candidate powercap files first; do not assume that an interface exists or write values into unknown files.

For thermal mapping, correlate the `type` and current temperature of every thermal zone, the `type` of each cooling device, and the kernel log. These mappings help distinguish thermal policy and throttling controls from physical fan controls.

## Safety

Do not disable thermal zones, force cooling devices to unusual states, or change power limits based solely on one snapshot. The firmware may be managing cooling independently of any user-visible Linux fan interface.
