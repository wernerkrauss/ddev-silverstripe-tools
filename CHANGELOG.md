# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project status and registry badges to `README.md`.
- GitHub Actions workflow for `ddev/ddev-addon-checker`.
- Automated Bats test suite (`tests/test.bats`) and GitHub Actions CI workflow (`.github/workflows/tests.yml`).
- Repository linting workflow with ShellCheck, yamllint, markdownlint, and `.editorconfig`.
- Dependabot configuration for GitHub Actions updates (`.github/dependabot.yml`).
- GitHub issue templates (`bug_report.yml`, `feature_request.yml`) and pull request template.

### Fixed
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

[Unreleased]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/wernerkrauss/ddev-silverstripe-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wernerkrauss/ddev-silverstripe-tools/releases/tag/v0.1.0
