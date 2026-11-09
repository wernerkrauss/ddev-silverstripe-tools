# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.3] - 2026-11-09

### Added

- `ddev yaml-lint` for Silverstripe `_config` and `lang` YAML files, including duplicate-key detection.
- Unit tests for the `phpunit` command's config file scanning and its `ddev ci` integration in
  `tests/phpunit-command.bats`, plus unit tests for the remaining `commands/web/*` scripts (missing-binary exit 127,
  argument passthrough, fallbacks) in `tests/web-commands.bats`. Both run without DDEV and are picked up by the
  existing `bats tests` CI run.
- README section "Development" documenting how to run the bats test suites locally (unit tests without DDEV,
  `tests/test.bats` with DDEV and Docker) and how to run the linters locally before pushing (ShellCheck, yamllint,
  markdownlint — same checks as the `lint` workflow). AGENTS.md now requires these local checks before pushing.

### Fixed

- `tests/web-commands.bats`: the "tool not installed" tests (`yaml-lint` without yamllint, `build` without sake)
  now run with a sanitized PATH, so they also pass on GitHub runners where yamllint is preinstalled (previously
  failed as `not ok 45 yaml-lint: missing yamllint exits 127 with install hint`).
- `ddev phpunit` no longer fails when no `phpunit.xml` is defined: without arguments it now scans for
  `phpunit.xml`/`phpunit.xml.dist` (project root first, then subdirectories) and passes the first match to PHPUnit via
  `--configuration`. When no configuration file is found, it prints a notice and exits with code `125`, which
  `ddev ci` reports as SKIP.

## [0.2.2] - 2026-10-09

### Added

- Apache-2.0 `LICENSE` file.
- `.gitattributes` to exclude development and CI files from release archives.
- DDEV version constraint (`>= v1.24.10`) in `install.yaml`.
- Bats assertion libraries and comprehensive health checks in `tests/test.bats`.
- Add-on Update Checker reference and workflow instructions in `AGENTS.md`.

### Changed

- Aligned `README.md` badges and GitHub Pull Request template with official DDEV add-on template standards.
- Updated GitHub Actions CI test matrix and workflow configuration.

## [0.2.1] - 2026-10-09

### Added

- Project status and registry badges to `README.md`.
- Automated Bats test suite (`tests/test.bats`) and GitHub Actions CI workflow (`.github/workflows/tests.yml`).
- Repository linting workflow with ShellCheck, yamllint, markdownlint, and `.editorconfig`.
- Dependabot configuration for GitHub Actions updates (`.github/dependabot.yml`).
- GitHub issue templates (`bug_report.yml`, `feature_request.yml`) and pull request template.

### Fixed

- Fixed `check-outdated-dependencies` to use breakpoint action.
- Fixed status checkmark icon in `ddev ci` output to use standard checkmark (`✔`) instead of emoji.
- Added `#ddev-generated` signature to all command files and configuration to allow DDEV to update files seamlessly.

## [0.2.0] - 2026-10-09

### Added

- `ddev check-outdated-dependencies` command to check for outdated Composer packages using `rector/swiss-knife`
  (with fallback to `rector/jack`).
- Helpful error messages with installation commands and Packagist URLs when a tool binary is missing.
- `AGENTS.md` documentation file detailing project architecture, conventions, and changelog guidelines.
- `.gitignore` file.

### Changed

- Improved `ddev ci` command with structured execution, formatted ANSI color output, and a final summary table.
- `ddev ci` now gracefully skips uninstalled tools (exit code `127`) without failing the suite.
- Updated `ddev ci` step name from "Jack" to "Outdated dependencies".
- Missing tool binaries in command scripts now return exit code `127` (`Command not found`) instead of `1`.
- `ddev jack` updated to transparently fall back to `rector/swiss-knife` since `rector/jack` is deprecated.
- Startup post-start hook updated to run `yarn build` in `DDEV_SILVERSTRIPE_THEME_PATH` when configured.

### Deprecated

- `ddev jack` is deprecated in favor of `ddev check-outdated-dependencies` and displays a deprecation warning on stderr.

### Fixed

- Fixed post-start hook execution and installation instructions in `README.md`.

## [0.1.0] - 2026-08-17

### Added

- Initial release with DDEV web commands tailored for Silverstripe CMS:
  - `ddev build`: Runs Silverstripe `sake` (`db:build --flush` or `dev/build flush`).
  - `ddev ci`: Runs test and quality check suite.
  - `ddev fix`: Formats PHP code using `phpcbf` and frontend code via Prettier.
  - `ddev jack`: Runs `rector/jack`.
  - `ddev lint`: Lints PHP code via `phpcs` and frontend code via Prettier.
  - `ddev phpunit`: Runs PHPUnit with Silverstripe DB credentials and unlimited memory.
  - `ddev prettier`: Runs Prettier in theme directory.
  - `ddev rector`: Runs Rector.
  - `ddev sspak`: Runs or installs Silverstripe `sspak`.
  - `ddev stan`: Runs PHPStan.
  - `ddev tinker`: Runs Silverstripe interactive shell (`ssshell`).
- Optional startup hooks in `config.netwerkstatt-tools.yaml` for automatic `composer install` and `ddev build`.
- Add-on installation manifest `install.yaml`.
- Documentation in `README.md`.

[Unreleased]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.2.3...HEAD
[0.2.3]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wernerkrauss/ddev-silverstripe-tools/releases/tag/v0.1.0
