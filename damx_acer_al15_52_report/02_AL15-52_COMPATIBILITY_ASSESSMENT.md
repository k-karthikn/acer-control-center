# 02 — Acer Aspire Lite AL15-52 Compatibility Assessment

**Evidence date:** 2026-10-19  
**Overall state:** **UNVERIFIED — do not force-enable hardware features yet.**

## 1. Machine evidence provided by the user

The diagnostic file `info.txt` reports:

- System: Acer Aspire Lite AL15-52
- BIOS/firmware vendor: Insyde Corp.
- BIOS version: `1.07.11iRAC` (2024-03-13)
- Embedded Controller firmware revision: `7.5`
- CPU/platform: Intel Alder Lake-U15; Intel UHD graphics
- Several PCI devices show subsystem vendor CLEVO/KAPOK (`1558:4150`).

The CLEVO/KAPOK subsystem string is an interesting investigation clue, but it **does not by itself establish that the laptop uses a Clevo firmware protocol or can use a Clevo/Nitro/Predator driver**. The system still reports Acer in SMBIOS.

## 2. Standard Linux interfaces in `hwc.txt`

The report showed:

- Thermal zones: `thermal_zone0` through `thermal_zone6`.
- Cooling devices: `cooling_device0` through `cooling_device13`.
- `intel_backlight` under `/sys/class/backlight`.
- Keyboard LEDs for Caps Lock, Num Lock and Scroll Lock.
- Three WMI device instances named with identifiers beginning `ABBC0F6B`, `ABBC0F6C`, and `ABBC0F6D`.
- No shown `rgb:kbd_backlight` or `kbd_backlight` entry.
- No clearly labelled `fan*_input` or `pwm*` entry was shown in the supplied interface listing.

Interpretation:

- Thermal-zone/cooling-device entries do not prove manual fan control; they can represent generic thermal cooling mechanisms such as CPU throttling.
- The absence of an RGB/backlight LED entry means the normal keyboard-light interface is not currently exposed in that snapshot. A vendor-specific driver could theoretically expose another interface, but the required protocol must be established first.
- Missing fan RPM/PWM attributes in this listing do not prove fan control is impossible; fan control may be mediated by firmware/WMI and only appear after a compatible driver loads.

## 3. Driver quirk compatibility

DAMX uses Div-Linuwu-Sense. Its driver source has model-specific DMI quirk entries. The inspected source includes support entries for several Nitro/Predator models and selected older Aspire/TravelMate devices. A search for `AL15-52` and `Aspire Lite` in that repository returned no matches.

This matters because a driver often needs to select the right set of operations for a specific laptop family. A generic Acer identity is not enough to determine whether methods for fan speed, thermal profile, or keyboard RGB match the embedded controller.

The DAMX FAQ discusses options such as `nitro_v4`, `predator_v4`, and `enable_all` for diagnostics or unsupported systems. These are not safe substitutes for a verified quirk. Forcing a quirk can make feature panels appear without proving the underlying method is supported.

## 4. WMI identifiers: what can and cannot be inferred

The user's system listed WMI device instances beginning with:

```text
ABBC0F6B-8EA1-11D1-00A0-C90629100000-1
ABBC0F6C-8EA1-11D1-00A0-C90629100000-2
ABBC0F6D-8EA1-11D1-00A0-C90629100000-0
```

The inspected Div-Linuwu-Sense source declares Acer WMI GUID aliases including:

```text
67C3371D-95A3-4C37-BB61-DD47B491DAAB
6AF4F258-B401-42FD-BE91-3D4AC2D7C0D3
676AA15E-6A47-4D9F-A2CC-1E6D18D14026
```

These identifiers are **not the same strings**. This is not a confirmed matching control path. It does not conclusively prove incompatibility either: the laptop can expose multiple WMI devices, and we have not inspected the full ACPI methods or firmware behavior.

The appropriate next step is read-only ACPI/WMI discovery and comparison with the driver method calls — not arbitrary WMI writes.

## 5. Feature-by-feature status

| Capability | Evidence now | Assessment |
|---|---|---|
| System information | SMBIOS, PCI devices and sensor data are available | Generic information likely works |
| Temperature monitoring | CPU, ACPI, Wi-Fi and NVMe readings exist | Generic monitoring likely works |
| Battery reading | BAT0 ACPI data exists | Generic battery data likely works |
| Linux power profile | `intel_pstate` reports active | CPU scaling exists; Acer OEM profiles remain unverified |
| Manual fan control | No clear fan/PWM interface shown; no exact DMI quirk | Unverified; do not force |
| Fan RPM monitoring | No clear fan RPM file shown | Unverified |
| Keyboard backlight | No normal RGB/kbd-backlight interface shown | Unverified; likely requires compatible vendor path if RGB hardware is present |
| Battery charge limiter | No evidence in the three diagnostic files that OEM charge-limit control is exposed | Unverified |
| LCD override / boot sound | No device-specific evidence | Unverified; likely not relevant until firmware support is established |
| NVIDIA GPU controls | Intel UHD only in PCI output | Not applicable to the reported configuration |

## 6. Verdict

The AL15-52 is **not on the project's confirmed compatibility list and has no observed model-specific quirk in the inspected driver source**. No available evidence yet shows that the laptop implements the exact WMI control methods expected by Linuwu-Sense.

Do not install the kernel module with forced Nitro/Predator options at this stage. First collect the read-only evidence in report 04. If the method mapping remains inconclusive, the next serious step is ACPI table analysis and possibly a hardware-specific quirk proposal — not trial-and-error writes to the embedded controller.

## Sources

- [DAMX compatibility list](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/Compatibility.md)
- [DAMX FAQ](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/FAQ.md)
- [Div-Linuwu-Sense driver source](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/src/linuwu_sense.c)
- [Div-Linuwu-Sense README](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/README.md)
