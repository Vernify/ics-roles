# storage_grow_pv

Grow an LVM Physical Volume (PV) to consume free space on its parent disk when that disk contains exactly one PV. The role:

- Rescans parent block devices to detect size changes
- Uses `growpart` to expand the PV's partition to the end of the disk
- Runs `pvresize` to make the new space available to LVM
- Skips disks that host multiple PVs (safety)

Defaults are organization-agnostic and should work across supported OSes.

## Inputs
- `storage_grow_pv_enabled` (bool, default: true): Toggle role behavior
- `storage_grow_pv_devices` (list[str], default: autodetect): Explicit PV devices
- `storage_grow_pv_rescan` (bool, default: true): Whether to rescan block devices

## Supported OS
- Ubuntu, Debian (installs `cloud-guest-utils`)
- RHEL/Rocky/Oracle/Fedora (installs `cloud-utils-growpart`)

## Usage
```yaml
- hosts: all
  become: true
  roles:
    - ics.common.storage_grow_pv
```

## Notes
- If more than one PV exists on the same parent disk, the role will not modify partitions on that disk.
- For NVMe devices, `growpart` is invoked with the correct disk path (e.g., `/dev/nvme0n1` and partition number).
