# 03 — CachyOS Kernel and Installation Risks

**User kernel from supplied diagnostic:** `7.2.11-1-cachyos`  
**Evidence date:** 2026-10-19

## 1. Kernel build compatibility is a real concern

DAMX installs an out-of-tree kernel module. A working GUI or daemon is not enough: the module must compile against the exact running kernel's build tree and must load successfully.

The DAMX release page lists `1.0.2-h1`, published 2026-07-23, with a hotfix described as addressing LLVM kernel compatibility. The current repository also contains user reports from CachyOS on 7.2.x kernels about Clang/LLVM compilation errors involving string functions and toolchain selection. Another report describes a manual fix and success on an Acer Nitro AN515-46, but that is not a test of the AL15-52.

These reports are not perfectly consistent, so treat compilation support as a version-specific check. Verify which exact source and installer are in the downloaded release before running anything. Don't assume a successful build of the GUI means the kernel driver built.

Relevant issue/release records:

- [DAMX 1.0.2-h1 release](https://github.com/PXDiv/Div-Acer-Manager-Max/releases/tag/1.0.2-h1)
- [CachyOS LLVM/Clang build report #284](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/284)
- [Report of a driver build fix #276](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/276)
- [Earlier CachyOS LLVM build report #224](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/224)

## 2. Kernel headers and compiler

Before any attempted build, confirm the headers/build tree exist for the *running* kernel and inspect how that kernel was compiled:

```bash
uname -r
cat /proc/version
ls -ld "/usr/lib/modules/$(uname -r)/build"
```

On CachyOS, the correct compiler/linker may need to match the kernel's LLVM toolchain. Do not apply random `sed` replacements to driver source as a default procedure. If the official release fails to build, preserve the full build log and compare it against a current upstream fix before editing source.

Installing headers and toolchain packages may be necessary, but it does not resolve hardware compatibility.

## 3. Secure Boot

An out-of-tree kernel module may be rejected if Secure Boot policy requires signed modules. DAMX's FAQ describes module signing/MOK enrollment on supported shim-based setups. Arch-family installations may instead use a local `sbctl` signing arrangement, depending on the machine's boot setup.

Before changing Secure Boot configuration:

- Check whether Secure Boot is enabled.
- Understand the current bootloader and key-management setup.
- Do not disable Secure Boot casually or enroll an unfamiliar key without understanding the consequences.
- Have a working boot entry and recovery path before changing kernel modules.

## 4. Installer scope

DAMX is not only a standalone GUI package. Its setup can install the kernel module, daemon, service files, permissions and application. These are privileged system changes. The driver is designed around Acer WMI and may replace or alter the normal Acer WMI control path depending on the installer/module implementation.

Before installation, inspect the exact installer and its cleanup/uninstall behavior. Ensure that the provided uninstaller actually removes the module, daemon, services, configuration and any driver overrides. Save copies of relevant current configuration.

## 5. Failure modes worth anticipating

- Kernel module build fails due to changed Linux APIs or compiler mismatch.
- Module builds but is blocked by Secure Boot signing policy.
- Module loads but the model is identified as unknown or only generic interfaces appear.
- A forced quirk exposes controls that fail with firmware errors.
- Fan speed writes fail or do not correspond to the expected units/arguments.
- GUI and daemon disagree about detected capabilities or do not restart after driver installation.
- A kernel update breaks the out-of-tree build until the project is patched.

## 6. Risk controls

1. Run the read-only checks first; do not install simply to find out whether the model is supported.
2. Keep a known-good bootable kernel and ensure you can reach a TTY/recovery shell.
3. Do not force `nitro_v4`, `predator_v4`, or `enable_all` on the AL15-52 without protocol evidence.
4. Do not write directly to ACPI/EC registers and do not set fan speed to a guessed value.
5. If a module is eventually tested, begin with detection/read-only outputs and generic information, not fan override, charge calibration, LCD override or keyboard RGB writes.
6. Record the exact release tag, commit, kernel version, module compiler, build log and `journalctl -k` output.

## Sources

- [DAMX releases](https://github.com/PXDiv/Div-Acer-Manager-Max/releases)
- [DAMX FAQ](https://github.com/PXDiv/Div-Acer-Manager-Max/blob/main/FAQ.md)
- [DAMX issue #284](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/284)
- [DAMX issue #276](https://github.com/PXDiv/Div-Acer-Manager-Max/issues/276)
- [Div-Linuwu-Sense Makefile](https://github.com/PXDiv/Div-Linuwu-Sense/blob/main/Makefile)
