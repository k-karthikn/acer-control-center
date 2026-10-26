# 05 — Recommendation and Source Register

**Target:** Acer Aspire Lite AL15-52 / CachyOS  
**Review date:** 2026-10-19

## 1. Recommendation

**Recommendation: investigate, but do not install the driver yet.**

DAMX is technically more promising than a GUI that only consumes generic Linux interfaces because it includes a custom Acer WMI/ACPI kernel module. However, the exact AL15-52 model is not on the published confirmed-compatibility list, and the inspected driver source does not show a model-specific AL15-52/Aspire Lite quirk. The user's currently exposed WMI identifiers do not directly match the principal WMI aliases declared in the inspected source. These are meaningful gaps in evidence.

The safest path is:

1. Run the read-only preflight commands in report 04.
2. Compare exact WMI GUIDs, ACPI devices/methods, and DMI model identity against the selected driver revision.
3. Check the installer and uninstaller in the exact release archive.
4. Resolve kernel/compiler and Secure Boot setup on CachyOS before a driver build.
5. If the protocol looks compatible, test in a controlled way with a recovery path. Start with module detection and read-only outputs, never forced fan/RGB/EC writes.
6. If no compatible control method is identified, gather evidence for a model-specific quirk or kernel-driver investigation rather than forcing a Nitro/Predator profile.

## 2. Decision table

| Question | Current answer | Confidence |
|---|---|---|
| Is DAMX a genuine hardware-control project? | Yes; it includes a kernel module and daemon as well as a GUI | High |
| Is it universal for all Acer laptops? | No; its driver uses model-specific quirks and compatibility is hardware-dependent | High |
| Is AL15-52 officially/testedly supported? | Not in the inspected compatibility list | High for the current list reviewed |
| Does the driver source have a clear AL15-52 quirk? | No exact `AL15-52`/`Aspire Lite` match found by source search | High for inspected source revision |
| Will it compile on the user's current CachyOS kernel? | Unknown until exact release/source and build are checked; similar CachyOS LLVM build problems have been reported | Medium |
| Will keyboard lighting work? | Unknown; user's ordinary sysfs listing lacks an RGB keyboard-light interface | Low/unknown |
| Will manual fan control work? | Unknown; no exact model support and no clearly exposed standard fan control found | Low/unknown |
| Should `enable_all` or a forced Nitro/Predator quirk be used now? | No | High-confidence safety recommendation |

## 3. Sources reviewed

The repository pages below were reviewed on 2026-10-19. Repository main-branch content can change; record the commit/tag when making a future test.

### Primary project

- [Div Acer Manager Max repository](https://github.com/PXDiv/Div-Acer-Manager-Max)
- [DAMX README](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/README.md) — claims, architecture, installation steps, project status.
- [Compatibility list](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/Compatibility.md) — models and stated distro/kernel support.
- [FAQ](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/FAQ.md) — unsupported-model guidance, quirks, kernel headers and Secure Boot considerations.
- [Release 1.0.2-h1](https://github.com/PXDiv/Div-Acer-Manager-Max/releases/tag/1.0.2-h1) — release dated 2026-07-23; release notes mention LLVM kernel compatibility.

### Driver

- [Div-Linuwu-Sense repository](https://github.com/PXDiv/Div-Linuwu-Sense)
- [Div-Linuwu-Sense README](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/README.md) — interface examples and warnings that its WMI behavior is reverse-engineered and not guaranteed across models.
- [Driver source (`linuwu_sense.c`)](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/src/linuwu_sense.c) — Acer WMI GUID aliases, module implementation and DMI quirk table.
- [Driver Makefile](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/Makefile)

### Relevant compatibility/build reports

- [Issue #284 — LLVM/Clang build failure report on CachyOS kernel 7.2.9](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/284)
- [Issue #276 — report describing a driver build fix](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/276)
- [Issue #224 — earlier CachyOS compiler mismatch](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/224)
- [Issue #285 — fan-speed write error reported by another user](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/285)

## 4. Limitations

- No live installation or runtime test has been performed on the user's AL15-52.
- No full DSDT/SSDT analysis was performed as part of this report.
- A missing DMI quirk is not proof of impossibility; it does mean support is not established and probably requires further compatibility work.
- Issue reports and repository documentation are evidence of project behavior and user experiences, not guarantees for a different model.
