# gitlab-runner
Local GitLab Runner (Docker executor) managed via docker-compose.

This repository provides a minimal setup for running a self‑hosted GitLab Runner on your machine and executing CI jobs inside Docker containers by binding the host Docker socket.

Important: Treat the runner token and `config/` contents as secrets. Do not commit them to a public repository.

## Prerequisites

- Docker and docker-compose installed
- Access to your GitLab instance and a registration token for a project/group/instance

## Quick start

1) Start the runner container

```
docker-compose up -d
```

2) Register the runner (interactive)

```
docker exec -it gitlab-runner gitlab-runner register
```

When prompted:
- GitLab instance URL: your GitLab URL (e.g. `https://gitlab.example.com`)
- Registration token: obtain from GitLab (Project → Settings → CI/CD → Runners → Register a runner)
- Description: a name for this runner (e.g. `home-pc-docker`)
- Tags: comma-separated list (optional)
- Executor: `docker`
- Default Docker image: e.g. `alpine:3.20`

This will create `config/config.toml` inside the mounted volume.

3) Verify the runner status in GitLab under Runners. It should appear as “online”.

## Non-interactive registration (optional)

If you prefer a one‑liner (replace the env values accordingly):

```
docker exec \
  -e REGISTER_NON_INTERACTIVE=true \
  -e CI_SERVER_URL="https://gitlab.example.com" \
  -e REGISTRATION_TOKEN="<TOKEN>" \
  -e RUNNER_NAME="home-pc-docker" \
  -e RUNNER_EXECUTOR="docker" \
  -e RUNNER_TAG_LIST="local,docker" \
  -e DOCKER_IMAGE="alpine:3.20" \
  -it gitlab-runner gitlab-runner register
```

## Recommended `config/config.toml`

After registration, the runner writes its configuration to `config/config.toml`. Below is a sensible baseline you can adapt. Items marked with <...> must be customized.

```
concurrent = 5
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "home-pc-docker"
  url = "https://gitlab.example.com"
  token = "<RUNNER_TOKEN_FROM_REGISTRATION>"
  executor = "docker"
  [runners.cache]
    MaxUploadedArchiveSize = 0
  [runners.docker]
    tls_verify = false
    image = "alpine:3.20"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    pull_policy = "if-not-present"
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
    shm_size = 268435456
    network_mtu = 0
```

Notes:
- `concurrent` controls how many jobs the runner can execute in parallel (total across all registered runners in this file). Set based on CPU/RAM. 4–6 is typical for a dev box.
- This setup uses the host Docker socket. Jobs can run `docker` commands from inside the build container without DinD. Keep `privileged = false` unless your jobs require it.
- `shm_size` is set to ~256MiB to help browsers/Chromium. Increase if your jobs need more shared memory.
- `pull_policy` of `if-not-present` reduces network pulls; set `always` if you want fresh images each job.
- Caching uses `/cache` volume. Configure cache sections in your `.gitlab-ci.yml` to take advantage of it.

Security:
- The `token` is sensitive; rotate it if it is ever exposed. Prefer storing this repository privately, or exclude `config/` from version control.
- Anyone with access to this machine and the Docker socket can control Docker; ensure the host is trusted.

## Typical operations

- Restart the runner after config changes:

```
docker-compose restart
```

- View logs:

```
docker logs -f gitlab-runner
```

- Update to the latest runner image (optional):

```
docker-compose pull && docker-compose up -d
```

To pin a specific version, change the image in `docker-compose.yml`, for example: `gitlab/gitlab-runner:17.5.1`.

## Using Docker in your jobs

- Because the host Docker socket is mounted, your job images need the Docker CLI if they run `docker` commands. For Alpine-based images, install it inside the job with:

```
apk add --no-cache docker-cli
```

Alternatively, use an image that already contains the Docker CLI.

## Troubleshooting

- Runner shows as offline: confirm the URL and token in `config/config.toml` match GitLab and that your network/firewall allows outbound HTTPS to GitLab.
- Permission denied talking to Docker: ensure `/var/run/docker.sock` is mounted (see `docker-compose.yml`) and your job image has the Docker CLI if needed.
- Jobs need more shared memory: increase `shm_size` in `config.toml` (e.g., `shm_size = 536870912` for 512MiB) and restart the runner.

## Repository hygiene

- Do not commit `config/config.toml` or `config/.runner_system_id` to a public repo. If they are already committed, rotate the runner token in GitLab and remove the files from version control history if possible.
