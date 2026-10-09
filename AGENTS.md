# AGENTS.md

## Project Overview

`ddev-silverstripe-tools` is a DDEV add-on providing custom DDEV web commands and optional startup hooks tailored for Silverstripe CMS projects.

### Key Objectives & Architecture
- **Non-intrusive container commands**: Implements wrapper commands in `commands/web/` that execute standard PHP and Silverstripe CLI tools inside the DDEV `web` container.
- **Fail-safe & Missing Binary Detection**: Commands check for project-local binaries (`vendor/bin/*`) and exit with code `127` (`Command not found`) and actionable installation instructions (including Packagist URLs) when a tool is not installed.
- **Aggregated CI Tooling (`ddev ci`)**: Runs a suite of quality checks (PHPUnit, PHPCS / Prettier, Rector, PHPStan, Outdated Dependencies) with formatted ANSI output, skips uninstalled tools gracefully without failing the suite, and prints a final status report.
- **Optional Start Hooks**: Configured via `config.netwerkstatt-tools.yaml`, allowing automated `composer install`, `ddev build`, and frontend asset building (Yarn) if enabled through environment variables.

---

## Directory Structure

- `commands/web/`: Bash scripts installed as DDEV web commands:
  - `build`: Runs Silverstripe `sake` (`db:build --flush` or `dev/build flush`).
  - `check-outdated-dependencies`: Checks for outdated dependencies via `rector/swiss-knife` (with fallback to `rector/jack breakpoint`).
  - `ci`: Runs full CI check suite (PHPUnit, Lint, Rector dry-run, PHPStan, Outdated dependencies) with summary table.
  - `fix`: Formats PHP code with `phpcbf` and frontend code with Prettier.
  - `jack`: Backward-compatibility wrapper for `rector/jack` and `rector/swiss-knife`.
  - `lint`: Lints PHP code using `phpcs` and frontend code via Prettier if theme path is configured.
  - `phpunit`: Runs `vendor/bin/phpunit` with Silverstripe DB credentials and unlimited memory.
  - `prettier`: Runs Prettier check/write within the configured theme path.
  - `rector`: Runs `vendor/bin/rector`.
  - `sspak`: Runs or auto-installs Silverstripe's `sspak` utility.
  - `stan`: Runs `vendor/bin/phpstan` using project-specific config.
  - `tinker`: Runs Silverstripe interactive shell (`ssshell`).
- `config.netwerkstatt-tools.yaml`: DDEV configuration providing the optional `post-start` hook.
- `install.yaml`: DDEV add-on manifest listing files to be copied into `.ddev/`.
- `README.md`: User documentation on installation, usage, and environment variables.

---

## Environment Variables

- `DDEV_SILVERSTRIPE_AUTO_START`: Enables the `post-start` hook (`composer install`, `ddev build`).
- `DDEV_SILVERSTRIPE_AUTO_FRONTEND`: Triggers `yarn build` in the `post-start` hook if enabled.
- `DDEV_SILVERSTRIPE_THEME_PATH`: Specifies the theme directory path for Prettier formatting and frontend build commands.

---

## Conventions & Development Guidelines

- **Bash Script Standards**: All command scripts use `set -euo pipefail`.
- **Exit Code Convention**:
  - Missing project dependencies/binaries must return exit code `127` with helpful stderr messages.
  - Actual check/test failures return standard non-zero exit codes (usually `1`).
- **Add-on File List**: Any new or removed command scripts in `commands/web/` must be synchronized with `install.yaml` under `project_files`.

---

## Changelog Guidelines

- The project uses a `CHANGELOG.md` following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
- Adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
- **External Contributors**: Always mention external contributors (non-Dependabot) with their GitHub handle (e.g., `(thanks to [@username](https://github.com/username))`).
- **Issue Tracking**: Check if a commit fixes an issue (look for "fixes #123" or similar in commit messages) and link it in the changelog.
- **Breaking Changes**: Clearly mark breaking changes and mention any incompatibilities (e.g., with specific `rector/rector` versions).
- **Language**: Changelog entries must be written in English.
- **Line Length**: Ensure lines in `CHANGELOG.md` do not exceed 120 characters.

---

## Release Process

When preparing and publishing a new release:
1. **Update `CHANGELOG.md`**:
   - Move entries from `[Unreleased]` to a new version section: `## [X.Y.Z] - YYYY-MM-DD`.
   - Update diff links at the bottom (`[Unreleased]`, `[X.Y.Z]`).
   - Keep an empty `## [Unreleased]` section at the top.
   - Verify line length does not exceed 120 characters.
2. **Commit changes**:
   - Create a commit for the release: `git commit -m "Release vX.Y.Z"` (include co-author if required).
3. **Tag the release**:
   - Create a Git tag for the version: `git tag vX.Y.Z`.
4. **Push commits and tags**:
   - Push the release commit and tags: `git push origin main --tags`.
5. **Create GitHub Release** (optional/recommended):
   - Create a GitHub Release using the tag `vX.Y.Z` and copy release notes from `CHANGELOG.md`.

---

## References & DDEV Add-on Standards

- **DDEV Add-on Template**: [ddev/ddev-addon-template](https://github.com/ddev/ddev-addon-template)
- **DDEV Add-on Maintenance Guide**: [DDEV Blog: Add-on Maintenance Guide](https://ddev.com/blog/ddev-add-on-maintenance-guide/)
- **Recommended Tools & Practices**:
  - Add-on Update Checker: `curl -fsSL https://ddev.com/s/addon-update-checker.sh | bash` to check conformity with the official DDEV add-on template.
  - GitHub Actions CI matrix with Bats tests (`tests/test.bats`) for validating `ddev add-on get` and command execution.
  - Linters: ShellCheck for bash scripts, markdownlint for docs, and yamllint for configuration files.
  - Dependabot / auto-merge workflows for keeping GitHub Actions updated.
