#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# Unit tests for the remaining commands/web/* scripts: missing-binary handling
# (exit 127 + install hint), argument passthrough, and fallback logic.
# No DDEV required: php/composer/jq/yarn and the project-local binaries are stubbed.
#
# Run locally from the add-on root directory (only bats-core required):
#   bats ./tests/web-commands.bats
# The tests also run in CI via `bats tests` (ddev/github-action-add-on-test),
# so they must not carry the `release` tag.

setup() {
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export CMD="$DIR/commands/web"
  export TESTDIR="$(mktemp -d "${TMPDIR:-/tmp}/web-commands.XXXXXX")"

  mkdir -p "$TESTDIR/bin" "$TESTDIR/project/vendor/bin"

  # Stub "php": drops "-d ..." arguments and executes the rest
  cat > "$TESTDIR/bin/php" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-d" ]]; then shift 2; fi
exec "$@"
EOF

  # Stub composer: logs args to stderr and answers "show silverstripe/framework" from $SS_FRAMEWORK_JSON
  cat > "$TESTDIR/bin/composer" <<'EOF'
#!/usr/bin/env bash
echo "COMPOSER_ARGS: $*" >&2
if [[ "$*" == *"show silverstripe/framework"* ]]; then printf '%s' "${SS_FRAMEWORK_JSON:-}"; fi
EOF

  # Stub jq: drains stdin (avoids SIGPIPE in the composer | jq pipeline), prints $JQ_RESULT
  cat > "$TESTDIR/bin/jq" <<'EOF'
#!/usr/bin/env bash
cat > /dev/null
printf '%s\n' "${JQ_RESULT:-}"
EOF

  chmod +x "$TESTDIR/bin/php" "$TESTDIR/bin/composer" "$TESTDIR/bin/jq"
  export PATH="$TESTDIR/bin:$PATH"

  # Clean PATH dir with only core tools symlinked. Tests that assert a tool is
  # NOT installed run with this PATH, because CI runners and dev machines may
  # have e.g. yamllint or sake installed globally.
  mkdir -p "$TESTDIR/cleanbin"
  local t
  for t in bash find sort head cat; do
    ln -s "$(command -v "$t")" "$TESTDIR/cleanbin/$t"
  done
}

teardown() {
  rm -rf "$TESTDIR"
}

# Creates an executable stub binary inside the stub project: make_bin <relpath> <label>
make_bin() {
  local path="$TESTDIR/project/$1" label="$2"
  mkdir -p "$(dirname "$path")"
  {
    echo '#!/usr/bin/env bash'
    echo "echo \"$label ARGS: \$*\""
  } > "$path"
  chmod +x "$path"
}

# Creates an executable stub tool on PATH: make_tool <name> <label>
make_tool() {
  {
    echo '#!/usr/bin/env bash'
    echo "echo \"$2 ARGS: \$*\""
  } > "$TESTDIR/bin/$1"
  chmod +x "$TESTDIR/bin/$1"
}

# Copies a command script and rewrites the hardcoded /mnt/ddev_config/commands/web
# path to a stub tree: stage_cmd <name>
stage_cmd() {
  mkdir -p "$TESTDIR/ddev-commands/web" "$TESTDIR/staged"
  sed "s|/mnt/ddev_config/commands/web|$TESTDIR/ddev-commands/web|g" "$CMD/$1" > "$TESTDIR/staged/$1"
}

# Creates a stub for a sibling command at the rewritten ddev path: stage_sibling <name> <label>
stage_sibling() {
  mkdir -p "$TESTDIR/ddev-commands/web"
  {
    echo '#!/usr/bin/env bash'
    echo "echo \"$2 ARGS: \$*\""
  } > "$TESTDIR/ddev-commands/web/$1"
  chmod +x "$TESTDIR/ddev-commands/web/$1"
}

# run_cmd <script-or-path> [args...] — runs from the stub project dir
run_cmd() {
  local script="$1"; shift
  [[ "$script" == */* ]] || script="$CMD/$script"
  cd "$TESTDIR/project" || return 1
  run bash "$script" "$@"
}

# run_cmd_127 <script-or-path> [args...] — like run_cmd, but for expected exit 127
run_cmd_127() {
  local script="$1"; shift
  [[ "$script" == */* ]] || script="$CMD/$script"
  cd "$TESTDIR/project" || return 1
  run -127 bash "$script" "$@"
}

assert_status() {
  if [ "$status" -ne "$1" ]; then
    echo "expected exit status $1, got $status" >&3
    echo "output: $output" >&3
    return 1
  fi
}

assert_output_contains() {
  case "$output" in
    *"$1"*) ;;
    *)
      echo "output does not contain: $1" >&3
      echo "output was: $output" >&3
      return 1
      ;;
  esac
}

assert_output_not_contains() {
  case "$output" in
    *"$1"*)
      echo "output should not contain: $1" >&3
      echo "output was: $output" >&3
      return 1
      ;;
    *)
      ;;
  esac
}

# --- stan -------------------------------------------------------------------

@test "stan: missing vendor/bin/phpstan exits 127 with install hint" {
  run_cmd_127 stan
  assert_output_contains "Error: phpstan is not installed."
  assert_output_contains "composer require --dev phpstan/phpstan"
}

@test "stan: passes arguments to vendor/bin/phpstan" {
  make_bin vendor/bin/phpstan PHPSTAN
  run_cmd stan analyze --level=5
  assert_status 0
  assert_output_contains "PHPSTAN ARGS: analyze --level=5"
}

# --- rector -----------------------------------------------------------------

@test "rector: missing vendor/bin/rector exits 127 with install hint" {
  run_cmd_127 rector
  assert_output_contains "Error: rector is not installed."
  assert_output_contains "composer require --dev rector/rector"
}

@test "rector: passes arguments to vendor/bin/rector" {
  make_bin vendor/bin/rector RECTOR
  run_cmd rector process src --dry-run
  assert_status 0
  assert_output_contains "RECTOR ARGS: process src --dry-run"
}

# --- tinker -----------------------------------------------------------------

@test "tinker: missing vendor/bin/ssshell exits 127 with install hint" {
  run_cmd_127 tinker
  assert_output_contains "Error: pstaender/ssshell is not installed."
  assert_output_contains "composer require --dev pstaender/ssshell"
}

@test "tinker: runs vendor/bin/ssshell" {
  make_bin vendor/bin/ssshell SSSHELL
  run_cmd tinker
  assert_status 0
  assert_output_contains "SSSHELL ARGS:"
}

# --- lint -------------------------------------------------------------------

@test "lint: missing vendor/bin/phpcs exits 127 with install hint" {
  run_cmd_127 lint
  assert_output_contains "Error: phpcs is not installed."
  assert_output_contains "composer require --dev squizlabs/php_codesniffer"
}

@test "lint: passes arguments to phpcs and skips prettier without theme path" {
  make_bin vendor/bin/phpcs PHPCS
  run_cmd lint --standard=PSR12
  assert_status 0
  assert_output_contains "PHPCS ARGS: --standard=PSR12"
  assert_output_not_contains "PRETTIER ARGS"
}

@test "lint: runs prettier check when DDEV_SILVERSTRIPE_THEME_PATH is set" {
  make_bin vendor/bin/phpcs PHPCS
  stage_cmd lint
  stage_sibling prettier PRETTIER
  mkdir -p "$TESTDIR/project/themes/mytheme"
  export DDEV_SILVERSTRIPE_THEME_PATH="themes/mytheme"
  run_cmd "$TESTDIR/staged/lint" --standard=PSR12
  assert_status 0
  assert_output_contains "PHPCS ARGS: --standard=PSR12"
  assert_output_contains "PRETTIER ARGS: check"
}

# --- fix --------------------------------------------------------------------

@test "fix: missing vendor/bin/phpcbf exits 127 with install hint" {
  run_cmd_127 fix
  assert_output_contains "Error: phpcbf is not installed."
}

@test "fix: runs phpcbf and prettier write" {
  make_bin vendor/bin/phpcbf PHPCBF
  stage_cmd fix
  stage_sibling prettier PRETTIER
  run_cmd "$TESTDIR/staged/fix"
  assert_status 0
  assert_output_contains "PHPCBF ARGS:"
  assert_output_contains "PRETTIER ARGS: write"
}

# --- jack -------------------------------------------------------------------

@test "jack: missing jack and swiss-knife exits 127, deprecation warning on stderr" {
  run_cmd_127 jack
  assert_output_contains "DEPRECATED"
  assert_output_contains "Error: rector/swiss-knife (or rector/jack) is not installed."
}

@test "jack: prefers vendor/bin/jack" {
  make_bin vendor/bin/jack JACK
  make_bin vendor/bin/swiss-knife SWISSKNIFE
  run_cmd jack check
  assert_status 0
  assert_output_contains "DEPRECATED"
  assert_output_contains "JACK ARGS: check"
  assert_output_not_contains "SWISSKNIFE ARGS"
}

@test "jack: falls back to vendor/bin/swiss-knife" {
  make_bin vendor/bin/swiss-knife SWISSKNIFE
  run_cmd jack check
  assert_status 0
  assert_output_contains "SWISSKNIFE ARGS: check"
}

# --- check-outdated-dependencies ---------------------------------------------

@test "check-outdated-dependencies: missing swiss-knife and jack exits 127" {
  run_cmd_127 check-outdated-dependencies
  assert_output_contains "Error: rector/swiss-knife is not installed."
  assert_output_contains "composer require --dev rector/swiss-knife"
}

@test "check-outdated-dependencies: prefers swiss-knife with breakpoint action" {
  make_bin vendor/bin/swiss-knife SWISSKNIFE
  make_bin vendor/bin/jack JACK
  run_cmd check-outdated-dependencies --foo
  assert_status 0
  assert_output_contains "SWISSKNIFE ARGS: breakpoint --foo"
  assert_output_not_contains "JACK ARGS"
}

@test "check-outdated-dependencies: falls back to jack" {
  make_bin vendor/bin/jack JACK
  run_cmd check-outdated-dependencies
  assert_status 0
  assert_output_contains "JACK ARGS: breakpoint"
}

# --- build ------------------------------------------------------------------

@test "build: Silverstripe 6 runs sake db:build --flush" {
  make_bin vendor/bin/sake SAKE
  export SS_FRAMEWORK_JSON='{"versions":["6.0.0"]}'
  export JQ_RESULT="6.0.0"
  run_cmd build
  assert_status 0
  assert_output_contains "SAKE ARGS: db:build --flush"
}

@test "build: older Silverstripe uses project-local sake dev/build flush" {
  make_bin vendor/bin/sake SAKE
  export JQ_RESULT="4.13.0"
  run_cmd build
  assert_status 0
  assert_output_contains "SAKE ARGS: dev/build flush"
}

@test "build: falls back to globally installed sake" {
  make_tool sake SAKE
  export JQ_RESULT="4.13.0"
  run_cmd build
  assert_status 0
  assert_output_contains "SAKE ARGS: dev/build flush"
}

@test "build: no sake anywhere exits 127 with install hint" {
  export JQ_RESULT="4.13.0"
  cd "$TESTDIR/project"
  # sanitized PATH: a globally installed sake on the host must not leak in
  run -127 env PATH="$TESTDIR/bin:$TESTDIR/cleanbin" bash "$CMD/build"
  assert_output_contains "Error: sake not found"
  assert_output_contains "composer require silverstripe/framework"
}

# --- sspak ------------------------------------------------------------------

@test "sspak: runs the global sspak binary with arguments" {
  mkdir -p "$TESTDIR/home/.composer/vendor/bin"
  {
    echo '#!/usr/bin/env bash'
    echo 'echo "SSPAK ARGS: $*"'
  } > "$TESTDIR/home/.composer/vendor/bin/sspak"
  chmod +x "$TESTDIR/home/.composer/vendor/bin/sspak"
  cd "$TESTDIR/project"
  run env HOME="$TESTDIR/home" bash "$CMD/sspak" snap list
  assert_status 0
  assert_output_contains "SSPAK ARGS: snap list"
}

@test "sspak: installs sspak globally via composer when missing" {
  mkdir -p "$TESTDIR/home"
  cd "$TESTDIR/project"
  run -127 env HOME="$TESTDIR/home" bash "$CMD/sspak"
  assert_output_contains "COMPOSER_ARGS: global require silverstripe/sspak:dev-master"
}

# --- prettier ---------------------------------------------------------------

@test "prettier: without DDEV_SILVERSTRIPE_THEME_PATH exits 1 with hint" {
  cd "$TESTDIR/project"
  run -1 bash "$CMD/prettier"
  assert_output_contains "Set DDEV_SILVERSTRIPE_THEME_PATH"
}

@test "prettier: theme directory must exist" {
  export DDEV_SILVERSTRIPE_THEME_PATH="themes/missing"
  cd "$TESTDIR/project"
  run -1 bash "$CMD/prettier"
  assert_output_contains "Theme directory not found: themes/missing"
}

@test "prettier: default is check, write with argument" {
  make_tool yarn YARN
  mkdir -p "$TESTDIR/project/themes/mytheme"
  export DDEV_SILVERSTRIPE_THEME_PATH="themes/mytheme"
  cd "$TESTDIR/project"
  run bash "$CMD/prettier"
  assert_status 0
  assert_output_contains "YARN ARGS: --cwd themes/mytheme prettier --check"
  run bash "$CMD/prettier" write
  assert_status 0
  assert_output_contains "YARN ARGS: --cwd themes/mytheme prettier --write"
}

# --- yaml-lint --------------------------------------------------------------

@test "yaml-lint: missing yamllint exits 127 with install hint" {
  cd "$TESTDIR/project"
  # sanitized PATH: GitHub runners have yamllint preinstalled, it must not leak in
  run -127 env PATH="$TESTDIR/cleanbin" bash "$CMD/yaml-lint"
  assert_output_contains "Error: yamllint is not installed in the web container."
}

@test "yaml-lint: no YAML files found exits 0 with message" {
  make_tool yamllint YAMLLINT
  run_cmd yaml-lint
  assert_status 0
  assert_output_contains "No Silverstripe _config or lang YAML files found."
  assert_output_not_contains "YAMLLINT ARGS"
}

@test "yaml-lint: lints _config and lang files, ignoring node_modules" {
  make_tool yamllint YAMLLINT
  mkdir -p "$TESTDIR/project/app/_config" "$TESTDIR/project/app/lang" "$TESTDIR/project/node_modules/mod/_config"
  touch "$TESTDIR/project/app/_config/routes.yml" "$TESTDIR/project/app/lang/en.yml" "$TESTDIR/project/node_modules/mod/_config/x.yml"
  run_cmd yaml-lint
  assert_status 0
  assert_output_contains "YAMLLINT ARGS: --config-file .ddev/.yamllint-silverstripe.yaml"
  assert_output_contains "./app/_config/routes.yml"
  assert_output_contains "./app/lang/en.yml"
  assert_output_not_contains "node_modules"
}

@test "yaml-lint: root .yamllint.yaml overrides the default config file" {
  make_tool yamllint YAMLLINT
  mkdir -p "$TESTDIR/project/app/_config"
  touch "$TESTDIR/project/app/_config/routes.yml" "$TESTDIR/project/.yamllint.yaml"
  run_cmd yaml-lint
  assert_status 0
  assert_output_contains "--config-file .yamllint.yaml"
}

# --- composer-validate --------------------------------------------------------

@test "composer-validate: missing composer.json exits 125 with notice" {
  run_cmd composer-validate
  assert_status 125
  assert_output_contains "Notice: no composer.json found, skipping composer validate."
}

@test "composer-validate: runs composer validate --no-check-publish" {
  touch "$TESTDIR/project/composer.json"
  run_cmd composer-validate
  assert_status 0
  assert_output_contains "COMPOSER_ARGS: validate --no-check-publish"
}

@test "composer-validate: passes extra arguments through" {
  touch "$TESTDIR/project/composer.json"
  run_cmd composer-validate --strict
  assert_status 0
  assert_output_contains "COMPOSER_ARGS: validate --no-check-publish --strict"
}

@test "composer-validate: composer not available exits 127 with hint" {
  touch "$TESTDIR/project/composer.json"
  cd "$TESTDIR/project"
  # sanitized PATH: CI runners and dev machines have composer installed globally
  run -127 env PATH="$TESTDIR/cleanbin" bash "$CMD/composer-validate"
  assert_output_contains "Error: composer is not available in the web container."
}

@test "composer-validate: validation failure is propagated" {
  touch "$TESTDIR/project/composer.json"
  printf '#!/usr/bin/env bash\necho "COMPOSER_ARGS: $*" >&2\nexit 1\n' > "$TESTDIR/bin/composer"
  chmod +x "$TESTDIR/bin/composer"
  run_cmd composer-validate
  assert_status 1
  assert_output_contains "COMPOSER_ARGS: validate --no-check-publish"
}
