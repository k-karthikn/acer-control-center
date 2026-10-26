# 04 — Read-only Preflight and Validation Plan

This plan is deliberately staged. Commands in sections A–D are intended to inspect the current machine without installing a driver or changing firmware settings. Do not execute any example from the driver's README that writes to `/sys/module/linuwu_sense/...` until compatibility is established.

## A. Confirm model, kernel, toolchain and Secure Boot status

```bash
printf '%s\n' '--- Kernel ---'
uname -a
cat /proc/version

printf '%s\n' '--- SMBIOS identity ---'
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name
sudo dmidecode -s baseboard-product-name
sudo dmidecode -s bios-version

printf '%s\n' '--- Matching kernel build tree ---'
ls -ld "/usr/lib/modules/$(uname -r)/build"

printf '%s\n' '--- Secure Boot status (if mokutil is installed) ---'
command -v mokutil >/dev/null && mokutil --sb-state || true
```

Do not publish the full output of `dmidecode`; it may contain serial numbers and system UUIDs. The commands above request only the fields needed for this check.

## B. Check currently loaded relevant modules

```bash
printf '%s\n' '--- Relevant modules ---'
lsmod | grep -Ei 'acer_wmi|linuwu_sense|wmi|platform_profile|intel_pstate' || true

printf '%s\n' '--- Module metadata ---'
modinfo acer_wmi 2>/dev/null | sed -n '1,30p'
modinfo linuwu_sense 2>/dev/null | sed -n '1,30p'
```

`modinfo linuwu_sense` returning no result usually means that module metadata is not available under that name for the current environment; it is not by itself a hardware diagnosis.

## C. Inventory WMI devices and standard control paths

```bash
printf '%s\n' '--- WMI instances ---'
find /sys/bus/wmi/devices -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort

printf '%s\n' '--- Backlights and LEDs ---'
find /sys/class/backlight /sys/class/leds -mindepth 1 -maxdepth 1 \
  -printf '%p -> %l\n' 2>/dev/null

printf '%s\n' '--- hwmon device names and fan/PWM attributes ---'
for d in /sys/class/hwmon/hwmon*; do
  [ -e "$d" ] || continue
  printf '\n%s: ' "$d"
  cat "$d/name" 2>/dev/null || true
  find "$d" -maxdepth 1 -type f \
    \( -name 'fan*_input' -o -name 'fan*_label' -o -name 'pwm*' \) \
    -printf '%f\n' 2>/dev/null
 done
```

## D. Map thermal zones and cooling-device types

```bash
for d in /sys/class/thermal/cooling_device*; do
  [ -e "$d" ] || continue
  printf '\n%s\n' "$d"
  printf 'type: '; cat "$d/type" 2>/dev/null || true
  printf 'current: '; cat "$d/cur_state" 2>/dev/null || true
  printf 'maximum: '; cat "$d/max_state" 2>/dev/null || true
done
```

This should tell us whether entries are CPU/package cooling devices or something explicitly associated with a fan. It does not require changing their state.

## E. Inspect driver source without installing it

```bash
mkdir -p ~/src
cd ~/src
git clone https://github.com/PXDiv/Div-Linuwu-Sense.git
cd Div-Linuwu-Sense

grep -nEi 'AL15-52|Aspire Lite' src/linuwu_sense.c || true
grep -nE 'MODULE_ALIAS|WMID_GUID|AMW0_GUID|acer_quirks|quirk_acer_' \
  src/linuwu_sense.c | less
```

An empty result for the exact model means there is no obvious literal model entry in that source revision. It does not prove the hardware methods cannot be adapted.

## F. Optional ACPI table inspection

Only if `acpica` tools are already installed, dump the DSDT into a temporary working directory and decompile it for **inspection only**:

```bash
mkdir -p ~/src/al15-52-acpi
cd ~/src/al15-52-acpi
sudo acpidump -n DSDT -b -o dsdt.dat
iasl -d dsdt.dat
```

Search the decompiled output for WMI device declarations, GUIDs, method names, and references to fan, thermal profile, keyboard light, charge limits, or vendor-specific control methods. Method names can be opaque, so absence of a human-readable string is not conclusive.

Before sharing the dump publicly, inspect it for serials or other device-specific information. Do not invoke ACPI methods or write EC registers during this phase.

## G. Decision gates

Proceed to any driver build only if all these are true:

- The exact current source/release has been identified.
- Kernel headers/build tree for `uname -r` exist.
- The kernel compiler/toolchain requirement is understood.
- The installer and uninstaller have been inspected.
- There is a backup/recovery boot path.
- There is a plausible match between this firmware's exposed WMI/ACPI methods and the driver operations.

Even after a successful module build, treat runtime compatibility as unverified until the module loads cleanly, detects the correct hardware, and only read-only features are checked. Test any write-capable setting one feature at a time, only after the protocol and safe value range are verified.
