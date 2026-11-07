# ddev-silverstripe-tools

[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com/wernerkrauss/ddev-silverstripe-tools)
[![tests](https://github.com/wernerkrauss/ddev-silverstripe-tools/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/wernerkrauss/ddev-silverstripe-tools/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/wernerkrauss/ddev-silverstripe-tools)](https://github.com/wernerkrauss/ddev-silverstripe-tools/commits)
[![release](https://img.shields.io/github/v/release/wernerkrauss/ddev-silverstripe-tools)](https://github.com/wernerkrauss/ddev-silverstripe-tools/releases/latest)
[![License](https://img.shields.io/github/license/wernerkrauss/ddev-silverstripe-tools)](LICENSE)

Reusable DDEV commands and optional project startup tooling for Silverstripe projects.

## Install

```bash
ddev add-on get wernerkrauss/ddev-silverstripe-tools --version v0.1.0
```

For local development:

```bash
ddev add-on get ~/dev/ddev-silverstripe-tools
```

The add-on installs project-specific commands into `.ddev/commands/web/` and records its version in
`.ddev/addon-metadata/`. Commit both the metadata and the installed project files.

## Update

Install a newer released tag again:

```bash
ddev add-on get wernerkrauss/ddev-silverstripe-tools --version v0.2.0
```

Review the resulting `.ddev` diff before committing it.

## Optional start hook

The add-on installs the hook disabled when `DDEV_SILVERSTRIPE_AUTO_START` is not set. Set it to `true` in a
project-specific DDEV config file to enable the hook:

```yaml
web_environment:
  - DDEV_SILVERSTRIPE_AUTO_START=true
  - DDEV_SILVERSTRIPE_AUTO_FRONTEND=true
```

The hook then runs Composer installation, Silverstripe build, and optionally the frontend build after DDEV starts.
When `DDEV_SILVERSTRIPE_THEME_PATH` is set to a theme directory, `yarn build` runs in that directory. If the variable
is empty or set to `/`, the build runs in the webroot.
Do not enable it for projects where startup should remain fast or where builds require a separate workflow.

When the variable is unset or set to `false`, the hook exits immediately and does not run `composer install`, the
Silverstripe build, or the optional frontend build.

For frontend formatting, configure the theme path in the project:

```yaml
web_environment:
  - DDEV_SILVERSTRIPE_THEME_PATH=themes/example
```

Without this variable, the PHP lint command skips the optional Prettier check.

## Commands

All commands run inside the web container and are available as `ddev <command>` after installation. Unless noted
otherwise, additional arguments are passed to the underlying tool.

### Silverstripe maintenance

| Command | Description |
| --- | --- |
| `ddev build` | Builds the Silverstripe database and flushes the configuration. Silverstripe 6 uses `sake db:build --flush`; older versions use `dev/build flush`. The command prefers the project-local `vendor/bin/sake` and falls back to a globally available `sake`. |
| `ddev tinker` | Opens the interactive Silverstripe shell provided by `pstaender/sshell`. The package must be installed in the project as `vendor/bin/ssshell`. |

### Tests and static analysis

| Command | Description |
| --- | --- |
| `ddev phpunit [args]` | Runs the project’s `vendor/bin/phpunit` with an unlimited PHP memory limit and the default DDEV/Silverstripe test database credentials (`root`/`root`). Without arguments, it scans for `phpunit.xml`/`phpunit.xml.dist` (project root first, then subdirectories) and passes the first match via `--configuration`. If no configuration file is found, it prints a notice and exits with code `125` (shown as SKIP by `ddev ci`). |
| `ddev stan [args]` | Runs the project’s `vendor/bin/phpstan`. |
| `ddev rector [args]` | Runs the project’s `vendor/bin/rector`. Use `ddev rector --dry-run` to inspect proposed changes. |
| `ddev jack [args]` | Runs `vendor/bin/jack` (Deprecated: Use `ddev check-outdated-dependencies` instead) or falls back to `vendor/bin/swiss-knife`. |
| `ddev check-outdated-dependencies [args]` | Checks for outdated Composer dependencies using `rector/swiss-knife` (`vendor/bin/swiss-knife check-outdated-dependencies`). |

### Code quality and formatting

| Command | Description |
| --- | --- |
| `ddev lint [phpcs-args]` | Runs PHP_CodeSniffer. If `DDEV_SILVERSTRIPE_THEME_PATH` is configured, it also checks the theme with Prettier. |
| `ddev yaml-lint [yamllint-args]` | Lints `_config` and `lang` YAML files in the project and its modules. Duplicate keys are errors. |
| `ddev fix` | Fixes PHP formatting with `vendor/bin/phpcbf` and formats the configured theme with Prettier. This changes files. |
| `ddev prettier [check\|write]` | Checks or formats `src/**/*.{js,css,scss}` below `DDEV_SILVERSTRIPE_THEME_PATH` using the theme’s Yarn/Prettier installation. The default is `check`. |
| `ddev ci` | Runs the standard project checks in sequence: PHPUnit, PHP/frontend linting, YAML linting, PHPStan, Rector (dry-run), and check-outdated-dependencies. |

### Deployment and packaging

| Command | Description |
| --- | --- |
| `ddev sspak [args]` | Runs Silverstripe’s `sspak`. If it is not available globally, the command installs `silverstripe/sspak:dev-master` via Composer before running it. |

### Special configuration and behaviour

- `DDEV_SILVERSTRIPE_THEME_PATH` is required by `ddev prettier` and enables the optional frontend check in `ddev lint`.
- `ddev fix` always invokes Prettier, so it requires `DDEV_SILVERSTRIPE_THEME_PATH` even when only PHP formatting is needed.
- Commands fail early with a clear error and installation hint when their required project-local binary is missing (exit code 127). The exception is `ddev sspak`,
  which installs its global binary automatically.
- `ddev phpunit` without arguments exits with code 125 (skipped, after printing a notice) when no `phpunit.xml`/`phpunit.xml.dist` exists in the project.
- `ddev ci` is a convenience wrapper around the other checks, including Silverstripe YAML linting; it runs all checks, treats uninstalled tools (exit code 127) and skipped checks (exit code 125) as skipped, collects their statuses, and outputs a summary at the end.

## Development

### Running the tests

The add-on ships bats test suites in `tests/`. The unit tests (`tests/phpunit-command.bats`, `tests/web-commands.bats`)
stub `php`, `composer`, `jq`, `yarn`, and the project-local binaries, so they run without DDEV — only bats-core is
required:

```bash
brew install bats-core   # Linux: apt install bats
bats tests/phpunit-command.bats tests/web-commands.bats
```

`tests/test.bats` validates the add-on installation inside a real DDEV project, so it additionally needs Docker and
DDEV locally plus the bats libraries:

```bash
brew install ddev bats-core bats-assert bats-file bats-support
bats ./tests/test.bats --filter-tags '!release'
```

CI runs `bats tests --filter-tags '!release'` on every push and pull request (see `.github/workflows/tests.yml`).

### Linting locally

Run the same checks as the `lint` workflow (see `.github/workflows/lint.yml`) before pushing:

```bash
# ShellCheck on commands/ (CI scans ./commands)
shellcheck commands/web/*

# yamllint on the whole repository with the project config
yamllint -c .yamllint.yaml .

# markdownlint on the root *.md files with the project config
npx --yes markdownlint-cli --config .markdownlint.yaml '*.md'
```

Install the tools with `brew install shellcheck yamllint markdownlint-cli` on macOS, or with
`sudo apt install shellcheck yamllint` and `npm install -g markdownlint-cli` (or just `npx`) on Ubuntu/WSL;
yamllint is also available via `pipx install yamllint`.
