#!/bin/bash
set -e

# Use environment variables to set shm_size
sed -i "s/shm_size = .*/shm_size = \"${CI_RUNNER_SHM_SIZE}\"/" /etc/gitlab-runner/config.toml

# Execute the original entrypoint
exec /entrypoint "$@"
