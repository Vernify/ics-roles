# Monitoring storage layout (Docker volumes and OS LVM)

This document explains how the monitoring stack provisions storage:

- A dedicated disk (default: /dev/sdb) is prepared for Docker data and volumes:
  - LVM PV -> VG `dockervg` -> LV `docker`
  - Filesystem: XFS
  - Mounted at /opt/docker_volumes (data-root for Docker is /opt/docker_volumes/docker-data)
  - Controlled by monitoring_common variables:
    - monitoring_common_prepare_docker_disk: true|false (default: false)
    - monitoring_common_docker_device: /dev/sdb
    - monitoring_common_docker_vg: dockervg
    - monitoring_common_docker_lv: docker
    - monitoring_common_docker_fs_type: xfs
    - monitoring_common_docker_mountpoint: /opt/docker_volumes

- System LVs can be resized prior to deployment using linux_lvm_resize role:
  - Provide a plan list of desired sizes; filesystems grow online.
  - Example:
    linux_lvm_resize_plan:
      - { vg: sysvg, lv: lv_opt,  size: '15G' }
      - { vg: sysvg, lv: lv_var,  size: '20G' }
      - { vg: sysvg, lv: lv_root, size: '50G' }

Notes:
- Ensure there is enough free space in the VG to satisfy requested sizes.
- The Docker data-root is applied early, and Docker is restarted before any docker_* tasks run, so images are stored under /opt/docker_volumes/docker-data.
