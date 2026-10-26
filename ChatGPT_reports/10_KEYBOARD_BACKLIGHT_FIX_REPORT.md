# Keyboard backlight fix — Acer Aspire Lite AL15-52

**Completed:** 26 October 2026  
**System:** CachyOS, kernel `7.3.0-4-cachyos`  
**Result:** The white keyboard backlight can be turned on, turned off, and adjusted from level 0 to 5 using a script without typing `sudo` or a password.

## What was wrong

The light worked in Windows and during startup, but Linux did not expose the usual keyboard-light control under `/sys/class/leds`. The old Hyprland script tried to use `/sys/class/leds/white:kbd_backlight`, which did not exist on this laptop. The keyboard hardware was working; Linux needed a way to reach its firmware control.

## How we found the control

1. We checked the laptop model, the LED interfaces, and the ACPI/WMI devices. There was no standard keyboard-backlight LED, but the laptop exposed a WMI method device.
2. We read and disassembled the laptop's ACPI DSDT table. Its `\_SB_.WMI_.WMBB` method contains a **read command `0x3D`** and a **set command `0x27`** for the white keyboard-light level. The set branch sends command `0xCA` to the embedded controller. This matches the [Clevo interface definitions](https://github.com/tuxedocomputers/tuxedo-drivers/blob/main/src/clevo_interfaces.h) and [white-light level definitions](https://github.com/tuxedocomputers/tuxedo-drivers/blob/main/src/clevo_leds.h) in TUXEDO's driver source.
3. With the user's approval, we installed CachyOS/Arch packages `dkms` and `acpi_call-dkms` so we could make a controlled ACPI call. An initial RGB command (`0x67`) returned a response but produced no visible light, so we did not use it for the fix.
4. The white-light read command returned `0`. A test of the white-light set command turned the light on, which the user confirmed. The value used in that first test (`0x80`) produced maximum brightness, and a subsequent read returned `5`.
5. We sent level `0`; the user confirmed that the light turned off. We then used levels `0` through `5` for the final controls. Level `1` gives a dim starting level when turning the light on.

The exact ACPI calls used by the final helper are:

```text
Read:  \_SB_.WMI_.WMBB 0 0x3D 0
Write: \_SB_.WMI_.WMBB 0 0x27 LEVEL   (LEVEL is 0, 1, 2, 3, 4, or 5)
```

These calls go through the `acpi_call` kernel module's `/proc/acpi/call` interface. The temporary ACPI table copies used for inspection were deleted after the investigation.

## What we installed and changed

| Item | Purpose |
| --- | --- |
| `dkms` and `acpi_call-dkms` packages | Provide the `acpi_call` kernel module. |
| [`keyboard_backlight/acer-kbd-control`](../keyboard_backlight/acer-kbd-control), installed at `/usr/local/libexec/acer-kbd-control` | Root-owned helper that reads or sets only this keyboard light's level. It loads `acpi_call` when needed, checks responses, and limits values to 0–5. |
| [`keyboard_backlight/50-acer-kbd-control.rules`](../keyboard_backlight/50-acer-kbd-control.rules), installed at `/etc/polkit-1/rules.d/50-acer-kbd-control.rules` | Polkit rule that lets only the active local account `karthi` run that exact helper as root without a password. The user explicitly approved this persistent rule. |
| [`keyboard_backlight/kbd_backlight.sh`](../keyboard_backlight/kbd_backlight.sh), installed at `/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh` | User-facing script for Hyprland or a terminal. It calls the helper through `pkexec`. |
| [`keyboard_backlight/kbd_backlight.previous.sh`](../keyboard_backlight/kbd_backlight.previous.sh) | Copy of the previous script, saved before replacement. |

No custom kernel driver or fan-control change was made. The password shared in the chat was not used or stored in these files.

### Compared with the earlier Clevo-driver fix

The [earlier guide](https://github.com/k-karthikn/keyboard) installs `clevo-drivers-dkms-git` and describes installing `linux-headers` to build it. On this system, **neither package is installed**. The matching `linux-cachyos-headers` and `linux-cachyos-lts-headers` were already present. This fix still uses one small DKMS-built kernel module, `acpi_call`, to send the two verified ACPI commands. It does not load the Clevo/TUXEDO driver or create the `white:kbd_backlight` LED interface. A package and DKMS check on 26 October showed only `acpi_call` as the keyboard-light-related DKMS module.

## How to use it

Run these as the normal user; do **not** prefix them with `sudo`:

```bash
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh status
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh on
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh off
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh up
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh down
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh toggle
/home/karthi/.config/hypr/custom/scripts/kbd_backlight.sh set 3
```

`0` means off and `5` is brightest. `on` starts at `1` if the light is off; otherwise it keeps the current level. `up` and `down` move one level at a time and stop at the ends. `toggle` switches between off and level `1`. `status` prints the current level, such as `1/5`.

For Hyprland, bind your preferred shortcuts to this script with `up`, `down`, `on`, or `off`. The existing configuration already referenced this script for the `XF86KbdLight` key events, but our `wev` test did not observe a usable event from the physical Fn/backlight key. The user chose to add their own shortcut; we did not edit the Hyprland bindings.

## Checks completed

| Check | Result |
| --- | --- |
| Turn on and turn off | User visually confirmed both actions worked. |
| `status`, `up`, `down` through the installed user script | Returned `0/5` → `1/5` → `0/5` without a password prompt. |
| Module absent before a command | Helper loaded `acpi_call` and returned `0/5` without a password prompt. |
| Invalid level (`set 6`) | Rejected; the light level stayed at `0/5`. |
| Actual reboot | Not tested yet. The module-on-demand check covers the main software step needed after reboot. |

The physical Fn/backlight key remains a separate key-event issue. The script itself is working and can be called from Hyprland with another shortcut.
