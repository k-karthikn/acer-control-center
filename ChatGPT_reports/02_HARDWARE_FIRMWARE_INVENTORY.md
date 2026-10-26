# Hardware and Firmware Inventory

## Source

Based on `info.txt`, generated on CachyOS. Personal device identifiers such as the serial number and system UUID are intentionally excluded.

## Platform summary

| Field | Reported value |
|---|---|
| OS | CachyOS Linux (`ID=cachyos`, Arch-family) |
| Kernel | `7.2.11-1-cachyos` |
| Architecture | x86_64 |
| SMBIOS version | 3.4 |
| System manufacturer | Acer |
| Product name | Aspire Lite AL15-52 |
| Motherboard manufacturer/product | Acer / Aspire Lite AL15-52 |
| BIOS vendor | INSYDE Corp. |
| BIOS version | `1.07.11iRAC` |
| BIOS release date | 2024-03-13 |
| Platform firmware revision | 7.11 |
| Embedded-controller firmware revision | 7.5 |
| UEFI | Reported supported |
| ACPI | Reported supported |

The firmware data is what SMBIOS reports. It does not independently confirm whether a BIOS update is available or whether the reported EC revision maps to a publicly documented firmware release.

## PCI devices and active drivers

The supplied `lspci -nnk` output includes the following important devices:

| PCI function | Device | Driver in use | Notes for this investigation |
|---|---|---|---|
| `00:00.0` | Intel Alder Lake-U15 host/DRAM controller `8086:4601` | `igen6_edac` | Core chipset function |
| `00:02.0` | Intel Alder Lake-UP3 GT2 graphics `8086:4628` | `i915` | Graphics/display path; `xe` is also listed as a possible module, but is not the active driver in this output |
| `00:04.0` | Intel Innovation Platform Framework processor participant `8086:461d` | `proc_thermal_pci` | Relevant to processor thermals; does not alone prove fan control |
| `00:0a.0` | Intel Platform Monitoring Technology `8086:467d` | `intel_vsec` | Vendor-specific platform capability; investigate only with documentation and read-only tools first |
| `00:14.0` | Intel USB 3.2 xHCI controller `8086:51ed` | `xhci_hcd` | USB controller |
| `00:14.3` | Intel CNVi Wi-Fi controller `8086:51f0` | `iwlwifi` | Wi-Fi; `hwmon` reports a Wi-Fi temperature sensor |
| `00:16.0` | Intel HECI/MEI communication controller `8086:51e0` | `mei_me` | Management Engine host interface; not evidence of laptop fan control |
| `00:1f.0` | Intel PCH eSPI controller `8086:5182` | No driver shown in excerpt | eSPI is an interface used for low-speed platform communication; a missing driver line does not identify the EC control protocol |
| `00:1f.3` | Intel PCH HD Audio `8086:51c8` | `snd_hda_intel` | Audio controller |
| `00:1f.4` | Intel SMBus controller `8086:51a3` | `i801_smbus` | SMBus controller |
| `00:1f.5` | Intel SPI controller `8086:51a4` | `intel-spi` | SPI controller |
| `00:1f.6` | Intel Ethernet controller `8086:1a1f` | `e1000e` | Ethernet |
| `01:00.0` | Phison PS5019-E19 NVMe controller `1987:5019` | `nvme` | Storage; NVMe temperature data appears in `sensors` |
| `02:00.0` | O2 Micro SD/MMC controller `1217:8621` | `sdhci_pci` | Card reader |

The listing also shows an Intel AX101 Wi-Fi 6 device and Intel Bluetooth device, a Chicony USB camera, and a C-Media USB audio device.

## Subsystem vendor note

Several Intel PCI functions in this report list `CLEVO/KAPOK Computer` as subsystem vendor, ID `1558:4150`. The system SMBIOS manufacturer and product name still report Acer Aspire Lite AL15-52.

This is a useful compatibility clue for source-code and hardware research, but it is not proof that a driver for another Clevo-branded laptop is compatible. A driver may depend on an exact product ID, board generation, EC implementation, firmware version, or WMI/ACPI method semantics.

## Why the ACPI/WMI path matters

The interface inventory reports an ACPI device `PNP0C14:00` with three WMI child instances. The WMI subsystem can expose vendor-specific platform functions, but the GUIDs alone do not tell us what each instance does. The next step is to retrieve device metadata and inspect the associated ACPI tables.

## Useful repeatable commands

```bash
uname -a
cat /etc/os-release
sudo dmidecode -t system -t baseboard -t bios
lspci -nnk
lsusb
```

Before sharing logs publicly, remove serial numbers, UUIDs, machine-specific identifiers, and any other personal inventory data.
