# Acer Aspire Lite AL15-52 keyboard backlight

This laptop's DSDT confirms Clevo WMI method `WMBB`. Method `0x3D` reads the
white keyboard backlight level and method `0x27` sets it. The tested level range
is 0 (off) through 5 (brightest). A level of 1 is used when turning the light on.

The root-owned helper in `/usr/local/libexec` accepts only the commands below.
The Polkit rule permits only the active local user `karthi` to run it without a
password. The user script at `~/.config/hypr/custom/scripts/kbd_backlight.sh`
calls that helper. Existing Hyprland bindings use this script.

```text
kbd_backlight.sh status
kbd_backlight.sh on
kbd_backlight.sh off
kbd_backlight.sh up
kbd_backlight.sh down
kbd_backlight.sh toggle
kbd_backlight.sh set 0..5
```

The `acpi_call-dkms` package must stay installed. The helper loads the module
on demand after reboot. No fan or unrelated firmware methods are used.
