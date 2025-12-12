# docker_runtime role

Installs and configures Docker Engine.

- Supports Debian/Ubuntu out of the box.
- Adds Docker's official repository and installs packages.
- Optionally configures `data-root` and merges extra daemon settings.
- Ensures the Docker service is enabled and started.
- Optionally adds users to the `docker` group.

Variables (prefix docker_runtime_):
- docker_runtime_install: bool (default: true)
- docker_runtime_repo_channel: stable|nightly|test (default: stable)
- docker_runtime_data_root: string, e.g. `/opt/docker_volumes/docker-data` (default: "")
- docker_runtime_daemon_extra: dict to merge into daemon.json (default: `{}`)
- docker_runtime_packages: list of Docker packages (default includes engine, CLI, containerd, buildx, compose plugin)
- docker_runtime_users: list of users to add to docker group (default: [])
- docker_runtime_service_name: service name (default: docker)

Example usage:

- name: Install Docker with custom data-root
  hosts: all
  roles:
    - role: ics.common.docker_setup
      vars:
        docker_runtime_data_root: /opt/docker_volumes/docker-data
