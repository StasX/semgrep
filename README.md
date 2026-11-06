# Semgrep Docker image

Licensed under the [MIT License](LICENSE).

A reusable Python Docker image for Semgrep Community Edition code scanning,
modeled on [StasX/checkov](https://github.com/StasX/checkov).
The runtime image contains Semgrep, with Hadolint, Checkov, and Trivy used separately in CI.

## Image

| Component | Configuration |
| --- | --- |
| Base | `python:3.13-alpine` (musl Linux) |
| Semgrep | `1.183.0`, pinned in `requirements.txt` |
| Installation | `/opt/semgrep-venv`, available on `PATH` |
| User | Non-root UID/GID `10001`, home `/home/semgrep` |
| Working directory | `/workspace` |
| Entrypoint / default | `semgrep` / `--help` |

The build upgrades Alpine packages, pins Git and CA certificates, and checks Python dependencies. Transitive
dependencies and the base-image digest are not locked. Registry rules can change
independently of the pinned scanner. Metrics and version checks are disabled.
There is no health check because this image runs a command and exits.
Bind-mounted targets must be readable by UID 10001.

## Build and verify

Docker must be running Linux containers. Building needs registry and PyPI access.

```sh
docker build --pull --no-cache -t semgrep:dev .
docker run --rm semgrep:dev --version
docker run --rm --entrypoint python semgrep:dev -m pip check
```

## Scan code

From the directory to scan, in PowerShell:

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/workspace,readonly" semgrep:dev scan --config p/default --error --strict --metrics=off .
```

POSIX shell:

```sh
docker run --rm --mount "type=bind,source=$(pwd),target=/workspace,readonly" semgrep:dev scan --config p/default --error --strict --metrics=off .
```

Use `--config p/dockerfile Dockerfile` to scan a Dockerfile, or
`--config /workspace/rules.yml` for local rules. Registry rules require network
access; local rules support offline scans. No Semgrep account or token is required
for these Community Edition scans. See the
[Semgrep CLI reference](https://docs.semgrep.dev/cli-reference).

`--error` makes findings return exit code 1; `--strict` also fails on warnings.
Other nonzero codes indicate scan/configuration errors. Add `--json` for JSON
output. The entrypoint already supplies `semgrep`, so arguments start with
`scan`, not a second `semgrep` command.

## CI and publishing

[GitHub Actions](.github/workflows/main.yml) runs on pushes, pull requests, and
manual dispatch:

1. Scan the Dockerfile in independent matrix jobs: Hadolint 2.15.1, Checkov 3.4.3,
   Semgrep 1.183.0 with `p/dockerfile`, and Trivy 0.76.1.
2. Build with `--pull` and no cache only after all checks pass.
3. Check the CLI and dependency compatibility.
4. Scan the built image with Trivy for OS and Python vulnerabilities at every
   severity, including issues without fixes. The Semgrep environment is included.
5. Publish the exact scanned image to Docker Hub on default-branch and tag runs.
   Pull requests and other branches never publish.

Scanner errors and findings fail CI and block publishing. Matrix jobs use
`fail-fast: false`, so one failing scanner does not stop the other scanners.
Bash pipefail preserves failures when output passes through `tee`.
The narrow `trivy-ignore.rego` policy excludes only the intentionally absent
Docker health check (DS-0026); no vulnerability exemptions are carried over.
Checkov likewise skips only the health-check rule (CKV_DOCKER_2) for this
command-line image. Its JSON report and diagnostic log are uploaded as
`checkov-reports-<run-id>-<attempt>`, including after failures.

Separate JSON reports and diagnostic logs are uploaded for each scanner even
after failure, when generated. Image metadata has its own artifact.
Artifact names end in the run ID and attempt and are retained for 14 days.
Build output is available in the Actions logs/build summary.

The version is the highest Git tag using `git tag --sort=-version:refname`,
or `0` when no tags exist, plus `latest`. Tags label the checked-out commit;
they do not change its source checkout. Published names are
`docker.io/<username>/semgrep:<version>` and `docker.io/<username>/semgrep:latest`.

Create a Docker Hub repository named `semgrep`. Add these GitHub Actions secrets:

- `DOCKERHUB_USERNAME`: the account owning the repository.
- `DOCKERHUB_TOKEN`: an access token allowed to push to that repository.

No vulnerability exemptions are configured. Scan results change with the
vulnerability database; any reported vulnerability blocks publishing.

## Assistant guidance

Shared guidance lives in [AGENTS.md](AGENTS.md).
[CLAUDE.md](CLAUDE.md) imports it and
[Copilot instructions](.github/copilot-instructions.md) reference it.
Keep credentials and personal assistant configuration outside Git.
