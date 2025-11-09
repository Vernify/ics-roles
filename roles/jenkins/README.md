# Jenkins (ics-roles)

This role deploys a Jenkins server container using the official Jenkins LTS image with persistent storage under `/opt/docker_volumes`.

Key features:
- Official `jenkins/jenkins:lts-jdk17` image by default
- Persistent data: `{{ jenkins_home }}` -> `/var/jenkins_home`
- Optional Docker socket mount for building container images (disabled by default)
- Lightweight, portable defaults (no reverse proxy, no org-specific settings)

Variables (defaults):
- `jenkins_image`: container image (default `jenkins/jenkins:lts-jdk17`)
- `jenkins_container_name`: container name (default `jenkins`)
- `jenkins_home`: host path for Jenkins home (default `/opt/docker_volumes/jenkins/home`)
- `jenkins_http_port`: host port for HTTP (default 8080)
- `jenkins_agent_port`: host port for JNLP agents (default 50000)
- `jenkins_network_name`: Docker network name (default `ci`)
- `jenkins_enable_docker`: mount `/var/run/docker.sock` (default `false`)
- `jenkins_env`: environment variables (default `{}`)

Tags: `jenkins`

Dependencies: Docker engine installed on the host.
