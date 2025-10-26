# docker_setup role

Installs and configures Docker Engine.

- Supports Debian/Ubuntu out of the box.
- Adds Docker's official repository and installs packages.
- Optionally configures `data-root` and merges extra daemon settings.
- Ensures the Docker service is enabled and started.
- Optionally adds users to the `docker` group.

Variables (prefix docker_setup_):
- docker_setup_install: bool (default: true)
- docker_setup_repo_channel: stable|nightly|test (default: stable)
- docker_setup_data_root: string, e.g. `/opt/docker_volumes/docker-data` (default: "")
- docker_setup_daemon_extra: dict to merge into daemon.json (default: `{}`)
- docker_setup_packages: list of Docker packages (default includes engine, CLI, containerd, buildx, compose plugin)
- docker_setup_users: list of users to add to docker group (default: [])
- docker_setup_service_name: service name (default: docker)

Example usage:

- name: Install Docker with custom data-root
  hosts: all
  roles:
    - role: ics.common.docker_setup
      vars:
        docker_setup_data_root: /opt/docker_volumes/docker-data
