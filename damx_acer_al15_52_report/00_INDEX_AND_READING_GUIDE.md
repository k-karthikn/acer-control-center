# Div Acer Manager Max (DAMX) — Report Pack

**Target system:** Acer Aspire Lite AL15-52 running CachyOS Linux  
**Evidence date:** 2026-10-19  
**Purpose:** Evaluate whether DAMX and its companion Linuwu-Sense kernel module are a sensible route to system/hardware-level controls on this exact laptop.

## Reading order

1. [Project review](01_PROJECT_AND_ARCHITECTURE_REVIEW.md) — what the project is, how its components work, and what its maturity indicators do and do not prove.
2. [AL15-52 compatibility assessment](02_AL15-52_COMPATIBILITY_ASSESSMENT.md) — compare the user's machine evidence with the project's stated model support and driver quirks.
3. [CachyOS and kernel risks](03_CACHYOS_KERNEL_AND_INSTALLATION_RISKS.md) — kernel-module compilation, Secure Boot, and installation implications.
4. [Safe preflight plan](04_READ_ONLY_PREFLIGHT_AND_VALIDATION.md) — staged commands that do not install the driver or write to hardware.
5. [Decision and sources](05_RECOMMENDATION_AND_SOURCE_REGISTER.md) — go/no-go recommendation and source list.

## Executive conclusion

DAMX is a substantially more relevant candidate than a GUI-only utility because it includes a kernel driver intended to expose Acer-specific controls through Linux interfaces. However, **the Acer Aspire Lite AL15-52 is not listed as a tested model, and no exact `AL15-52` / `Aspire Lite` match was found in the inspected Div-Linuwu-Sense source search**. Compatibility is therefore **unverified**, not confirmed.

The user's current evidence shows an Insyde firmware/EC, Intel Alder Lake-U15 platform, several WMI device instances, CPU/thermal sensor interfaces, and no standard `rgb:kbd_backlight` interface or clearly labelled fan RPM/PWM interface. The WMI IDs in that dump are not the same identifiers that the inspected driver declares as its principal Acer WMI aliases. This is a clue for further reverse engineering, not proof that support is impossible.

Do not install a privileged kernel driver just because the GUI looks mature. First perform the read-only checks in report 04, verify the actual release archive and kernel compiler, and establish the relevant firmware control path. Do not force gaming-model quirks or `enable_all` on an unverified Aspire Lite.

## Evidence labels used throughout

- **Confirmed:** directly present in the user's diagnostic outputs or inspected repository documentation/source.
- **Strong indication:** supported by the evidence but not tested on this exact laptop.
- **Unknown:** requires a test, deeper source review, or actual AL15-52 hardware evidence.
- **Not recommended:** an action that has material risk before compatibility is established.
