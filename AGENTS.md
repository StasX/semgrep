# Project guidance

Build a reusable Python Docker image for Semgrep Community Edition.
This is a command-line tooling image, not a service or web application.

- Keep the Dockerfile at the repository root and Semgrep pinned in requirements.txt.
- Use the Python Alpine base image and Alpine package/user management commands.
- Install Semgrep in /opt/semgrep-venv and keep it on PATH.
- Run as UID/GID 10001 with a writable home.
- Preserve scanner exit codes. Never suppress findings simply to pass CI.
- Keep Hadolint, Checkov, and Trivy in separate CI containers, outside the runtime image.
- Publish only the exact image that passed checks, on default-branch or tag runs.
- Keep documentation and commands consistent with the Docker entrypoint.
- Do not commit credentials, generated reports, or personal configuration.

For Docker or dependency changes, build and verify:

```sh
docker build --pull --no-cache -t semgrep:dev .
docker run --rm semgrep:dev --version
docker run --rm --entrypoint python semgrep:dev -m pip check
git diff --check
```

Use the PowerShell mount syntax from README.md on Windows.
Validate the workflow when changing CI, and report any checks not run.
