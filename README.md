# ddev-silverstripe-tools

Reusable DDEV commands and optional project startup tooling for Silverstripe projects.

## Install

```bash
ddev add-on get github.com/wernerkrauss/ddev-silverstripe-tools --version v0.1.0
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

The add-on installs the hook disabled. Enable it in a project-specific DDEV config file:

```yaml
web_environment:
  - DDEV_SILVERSTRIPE_AUTO_START=true
  - DDEV_SILVERSTRIPE_AUTO_FRONTEND=true
```

The hook then runs Composer installation, Silverstripe build, and optionally the frontend build after DDEV starts.
Do not enable it for projects where startup should remain fast or where builds require a separate workflow.

For frontend formatting, configure the theme path in the project:

```yaml
web_environment:
  - DDEV_SILVERSTRIPE_THEME_PATH=themes/example
```

Without this variable, the PHP lint command skips the optional Prettier check.

## Commands

The add-on provides `ddev build`, `ddev ci`, `ddev fix`, `ddev jack`, `ddev lint`, `ddev phpunit`, `ddev prettier`,
`ddev rector`, `ddev sspak`, `ddev stan`, and `ddev tinker`.
