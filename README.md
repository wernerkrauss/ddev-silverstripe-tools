# ddev-silverstripe-tools

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
ddev add-on get github.com/wernerkrauss/ddev-silverstripe-tools --version v0.2.0
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
| `ddev phpunit [args]` | Runs the project’s `vendor/bin/phpunit` with an unlimited PHP memory limit and the default DDEV/Silverstripe test database credentials (`root`/`root`). |
| `ddev stan [args]` | Runs the project’s `vendor/bin/phpstan`. |
| `ddev rector [args]` | Runs the project’s `vendor/bin/rector`. Use `ddev rector --dry-run` to inspect proposed changes. |
| `ddev jack [args]` | Runs `vendor/bin/jack` (Deprecated: Use `ddev check-outdated-dependencies` instead) or falls back to `vendor/bin/swiss-knife`. |
| `ddev check-outdated-dependencies [args]` | Checks for outdated Composer dependencies using `rector/swiss-knife` (`vendor/bin/swiss-knife check-outdated-dependencies`). |

### Code quality and formatting

| Command | Description |
| --- | --- |
| `ddev lint [phpcs-args]` | Runs PHP_CodeSniffer. If `DDEV_SILVERSTRIPE_THEME_PATH` is configured, it also checks the theme with Prettier. |
| `ddev fix` | Fixes PHP formatting with `vendor/bin/phpcbf` and formats the configured theme with Prettier. This changes files. |
| `ddev prettier [check\|write]` | Checks or formats `src/**/*.{js,css,scss}` below `DDEV_SILVERSTRIPE_THEME_PATH` using the theme’s Yarn/Prettier installation. The default is `check`. |
| `ddev ci` | Runs the standard project checks in sequence: PHPUnit, PHP/frontend linting, PHPStan, Rector (dry-run), and check-outdated-dependencies. |

### Deployment and packaging

| Command | Description |
| --- | --- |
| `ddev sspak [args]` | Runs Silverstripe’s `sspak`. If it is not available globally, the command installs `silverstripe/sspak:dev-master` via Composer before running it. |

### Special configuration and behaviour

- `DDEV_SILVERSTRIPE_THEME_PATH` is required by `ddev prettier` and enables the optional frontend check in `ddev lint`.
- `ddev fix` always invokes Prettier, so it requires `DDEV_SILVERSTRIPE_THEME_PATH` even when only PHP formatting is needed.
- Commands fail early with a clear error and installation hint when their required project-local binary is missing (exit code 127). The exception is `ddev sspak`,
  which installs its global binary automatically.
- `ddev ci` is a convenience wrapper around the other checks; it runs all checks, treats uninstalled tools (exit code 127) as skipped, collects their statuses, and outputs a summary at the end.
