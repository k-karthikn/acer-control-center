# CPU Power and Performance Controls

## What the supplied diagnostics confirm

The hardware inventory shows an Intel Alder Lake-U15 platform. The PCI device at `00:04.0` is reported as an Intel Innovation Platform Framework processor participant and is driven by `proc_thermal_pci`. The sensor file prints `intel_pstate` status as `active`.

These observations establish that relevant Linux CPU/thermal functionality is active. They do **not** reveal package power limits, frequency policy during load, platform profile support, or the precise cause of perceived lag while compiling.

## Interfaces worth discovering

### Intel P-state

```bash
cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null
find /sys/devices/system/cpu/intel_pstate -maxdepth 2 -type f -print 2>/dev/null
```

The directory may expose driver-specific scaling or energy-preference controls. Availability varies by driver, kernel configuration, and system state. Do not change values until their meaning and expected range are verified.

### ACPI platform profile

```bash
if [ -r /sys/firmware/acpi/platform_profile ]; then
    cat /sys/firmware/acpi/platform_profile
fi
if [ -r /sys/firmware/acpi/platform_profile_choices ]; then
    cat /sys/firmware/acpi/platform_profile_choices
fi
```

If neither file exists, the platform-profile interface may not be registered. This does not prove that no vendor-specific performance mode exists.

### Powercap interfaces

```bash
find /sys/class/powercap -maxdepth 5 -type f -print 2>/dev/null
```

List available files first. Do not write `constraint_*`, `energy_uj`, or other values during initial discovery. Different attributes have different semantics; many are read-only, and the available controls vary by driver.

### CPU frequency state and online CPUs

```bash
grep . /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver 2>/dev/null | head -40
grep . /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | head -40
grep . /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null | head -40
```

Some paths may not exist depending on driver mode and kernel configuration. That is normal. These commands only read values.

## Diagnosing slowdown under Android Studio builds

Do not infer the cause from the fact that the CPU is in a high-performance mode. The system may be experiencing CPU saturation, memory pressure, storage I/O, thermal/power throttling, or scheduling contention. A reproducible before/during/after capture is needed.

Capture at least:

1. Idle baseline.
2. Android Studio build while the lag is occurring.
3. A second run with the build stopped.

Record CPU frequency/policy where available, temperatures, memory pressure, I/O utilization, active power profile and exact kernel version for each test. Avoid changing several performance settings at once; it makes results uninterpretable.

Useful general-purpose observations:

```bash
uptime
free -h
vmstat 1 10
sensors
cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null
cat /sys/firmware/acpi/platform_profile 2>/dev/null
```

Install `sysstat` only if you specifically need tools such as `iostat`, and use consistent workloads across comparisons. The current three files alone cannot establish that CachyOS is assigning unfair preference to a build process or that Arch Linux had a different scheduling policy.

## Safe implementation strategy

Prefer supported CPUFreq, powercap, platform-profile, and power-management interfaces over raw MSR writes or undocumented EC commands. Change one variable at a time and maintain a way to restore the original setting. Do not disable thermal limits as a performance workaround.
