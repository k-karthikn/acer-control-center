# 01 — DAMX Project and Architecture Review

**Reviewed:** 2026-10-19  
**Primary project:** https://github.com/PXDiv/Div-Acer-Manager-Max

## 1. What DAMX is

Div Acer Manager Max (DAMX) is a graphical control center for Acer laptops. Its README describes performance/thermal profiles, manual/automatic fan modes, keyboard-backlight timeout, boot animation/sound toggles, LCD override, live hardware information, and a low-resource daemon. It uses an Avalonia-based GUI and depends on the companion **Div-Linuwu-Sense** kernel module for Acer-specific interfaces.

Companion driver: https://github.com/PXDiv/Div-Linuwu-Sense  
Driver source: https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/src/linuwu_sense.c

This architecture is meaningfully different from a GUI that only reads generic battery or sensor data. The kernel module implements Acer WMI/ACPI-related operations and exposes controls through kernel interfaces; the daemon and GUI then consume those interfaces.

## 2. Main components

| Component | Responsibility | Relevance to AL15-52 |
|---|---|---|
| DAMX GUI | Exposes profiles, monitoring and settings | Can only control features the daemon/driver successfully detects and implements |
| DAMX daemon | Detects driver features and coordinates requests | Could report unknown model or hide controls when no matching feature path is found |
| Div-Linuwu-Sense kernel module | Implements platform-specific hardware methods and exposes attributes | Critical compatibility gate; a wrong quirk could expose controls that do not match the firmware |
| Setup/installer scripts | Build/install module, set up daemon/GUI and services | Privileged, system-changing stage; should not be first step |

## 3. Project maturity: what the evidence says

Positive indicators:

- There is a GUI, daemon, kernel-driver repository and documented compatibility table rather than only a mockup.
- The driver contains explicit model-specific DMI quirk entries and supports multiple generations of Acer Nitro/Predator models and some older Acer systems.
- The project has releases, issue discussions and a documented installer/uninstaller.
- The release notes for `1.0.2-h1` explicitly say the hotfix addresses LLVM-built kernel compatibility.

Caveats:

- The DAMX README says the project is under **passive development**.
- The published release inspected for this report is `1.0.2-h1`, dated 2026-07-23. Recent issue reports in October 2026 still discuss build or feature-control problems. That means an attractive interface and a substantial codebase are not equivalent to verified support on all Acer laptops.
- Compatibility documentation is not fully consistent: `Compatibility.md` says officially tested distributions are Ubuntu 25+ and Kubuntu 25+, while the FAQ says the project is officially tested/supported on Ubuntu only. Treat CachyOS as a community-tested/unsupported environment unless the project explicitly clarifies otherwise.
- Issue reports show that control writes can fail for particular models or that keyboard features can behave incorrectly despite a driver/UI being present.

## 4. Feature claims versus generic system data

Generic operations such as displaying the battery percentage, reading CPU temperatures, or calling `powerprofilesctl` may work independently of Acer-specific support. The interesting controls — fan speed, OEM thermal profiles, vendor battery limiter, special keyboard lighting, LCD override and boot animation/sound — are only available when the hardware and firmware path matches the driver implementation.

DAMX should therefore be assessed feature-by-feature, not as a single all-or-nothing app. A working system-information page does not prove that fan control or keyboard lighting works.

## 5. Exact laptop match

The user's SMBIOS output reports:

- Manufacturer: Acer
- Product: Aspire Lite AL15-52
- Firmware vendor: INSYDE Corp.
- Firmware version: 1.07.11iRAC
- Embedded Controller firmware revision: 7.5
- Intel Alder Lake-U15 platform; Intel UHD graphics

The inspected DAMX compatibility list does not list AL15-52. A code search of Div-Linuwu-Sense for `AL15-52` and `Aspire Lite` returned no matches. The driver's visible DMI quirk table contains many named systems, including selected Aspire models, but not this exact model.

**Conclusion:** DAMX is a useful research candidate, but AL15-52 compatibility has not been demonstrated.

## Sources

- [DAMX README](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/README.md)
- [Compatibility list](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/Compatibility.md)
- [FAQ](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/FAQ.md)
- [Div-Linuwu-Sense README](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/README.md)
- [Driver source](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/src/linuwu_sense.c)
