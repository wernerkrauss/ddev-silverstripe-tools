#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

# Unit tests for commands/web/phpunit (PHPUnit config file scanning) and its
# integration with commands/web/ci. These tests do NOT require DDEV: php and
# the project-local binaries are stubbed.
#
# Run locally from the add-on root directory (only bats-core required):
#   bats ./tests/phpunit-command.bats
# The tests also run in CI via `bats tests` (ddev/github-action-add-on-test),
# so they must not carry the `release` tag.

setup() {
  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export SCRIPT_PHPUNIT="$DIR/commands/web/phpunit"
  export SCRIPT_CI="$DIR/commands/web/ci"
  export TESTDIR="$(mktemp -d "${TMPDIR:-/tmp}/phpunit-command.XXXXXX")"

  # Stub "php": drops the "-d memory_limit=-1" arguments and executes the rest
  mkdir -p "$TESTDIR/bin"
  cat > "$TESTDIR/bin/php" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-d" ]]; then shift 2; fi
exec "$@"
EOF
  chmod +x "$TESTDIR/bin/php"
  export PATH="$TESTDIR/bin:$PATH"

  # Stub project with a fake vendor/bin/phpunit that echoes its arguments
  mkdir -p "$TESTDIR/project/vendor/bin"
  cat > "$TESTDIR/project/vendor/bin/phpunit" <<'EOF'
#!/usr/bin/env bash
echo "PHPUNIT_ARGS: $*"
echo "CREDS: SS_DATABASE_USERNAME=${SS_DATABASE_USERNAME:-} SS_DATABASE_PASSWORD=${SS_DATABASE_PASSWORD:-}"
EOF
  chmod +x "$TESTDIR/project/vendor/bin/phpunit"
}

teardown() {
  rm -rf "$TESTDIR"
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

# Builds a stub .ddev/commands/web tree and a copy of the ci script pointing to it
setup_ci() {
  mkdir -p "$TESTDIR/ddev-commands/web"
  cp "$SCRIPT_PHPUNIT" "$TESTDIR/ddev-commands/web/phpunit"
  local c
  for c in lint yaml-lint rector stan check-outdated-dependencies composer-validate; do
    printf '#!/usr/bin/env bash\nexit 127\n' > "$TESTDIR/ddev-commands/web/$c"
    chmod +x "$TESTDIR/ddev-commands/web/$c"
  done
  sed "s|/mnt/ddev_config/commands/web|$TESTDIR/ddev-commands/web|g" "$SCRIPT_CI" > "$TESTDIR/ci"
}

assert_summary_status() {
  local line
  line="$(printf '%s\n' "$output" | grep "^$1:")"
  case "$line" in
    *"$2"*) ;;
    *)
      echo "summary line '$1:' should contain '$2', got: $line" >&3
      return 1
      ;;
  esac
}

@test "no arguments and no config file: notice on stderr and exit 125" {
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 125
  assert_output_contains "Notice: no phpunit.xml or phpunit.xml.dist found, skipping PHPUnit."
  assert_output_not_contains "PHPUNIT_ARGS"
}

@test "no arguments, phpunit.xml in root: passed via --configuration" {
  touch "$TESTDIR/project/phpunit.xml"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 0
  assert_output_contains "Using PHPUnit configuration file: phpunit.xml"
  assert_output_contains "PHPUNIT_ARGS: --configuration phpunit.xml"
}

@test "no arguments, phpunit.xml.dist in root is used" {
  touch "$TESTDIR/project/phpunit.xml.dist"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --configuration phpunit.xml.dist"
}

@test "config in subdirectory (app/phpunit.xml.dist) is found by the scan" {
  mkdir -p "$TESTDIR/project/app"
  touch "$TESTDIR/project/app/phpunit.xml.dist"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --configuration ./app/phpunit.xml.dist"
}

@test "root phpunit.xml wins over app/phpunit.xml.dist" {
  touch "$TESTDIR/project/phpunit.xml"
  mkdir -p "$TESTDIR/project/app"
  touch "$TESTDIR/project/app/phpunit.xml.dist"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --configuration phpunit.xml"
  assert_output_not_contains "app/phpunit.xml.dist"
}

@test "config files inside vendor/ are ignored" {
  touch "$TESTDIR/project/vendor/phpunit.xml.dist"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 125
  assert_output_contains "Notice: no phpunit.xml or phpunit.xml.dist found"
}

@test "config files inside node_modules/ and .git/ are ignored" {
  mkdir -p "$TESTDIR/project/node_modules/foo" "$TESTDIR/project/.git"
  touch "$TESTDIR/project/node_modules/foo/phpunit.xml" "$TESTDIR/project/.git/phpunit.xml"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 125
}

@test "explicit -c argument is passed through without scanning" {
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT" -c custom.xml
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: -c custom.xml"
  assert_output_not_contains "--configuration"
}

@test "explicit test path is passed through without scanning" {
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT" tests/FooTest.php
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: tests/FooTest.php"
  assert_output_not_contains "--configuration"
}

@test "--no-configuration is passed through even if phpunit.xml exists" {
  touch "$TESTDIR/project/phpunit.xml"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT" --no-configuration
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --no-configuration"
  assert_output_not_contains "--configuration phpunit.xml"
}

@test "option-only arguments are passed through without scanning" {
  mkdir -p "$TESTDIR/project/app"
  touch "$TESTDIR/project/app/phpunit.xml.dist"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT" --filter Foo
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --filter Foo"
  assert_output_not_contains "--configuration"
}

@test "silverstripe database credentials are passed to phpunit" {
  touch "$TESTDIR/project/phpunit.xml"
  cd "$TESTDIR/project"
  run bash "$SCRIPT_PHPUNIT"
  assert_status 0
  assert_output_contains "CREDS: SS_DATABASE_USERNAME=root SS_DATABASE_PASSWORD=root"
}

@test "missing vendor/bin/phpunit exits 127 with install hint" {
  rm "$TESTDIR/project/vendor/bin/phpunit"
  cd "$TESTDIR/project"
  run -127 bash "$SCRIPT_PHPUNIT"
  assert_output_contains "Error: phpunit is not installed."
  assert_output_contains "composer require --dev phpunit/phpunit"
}

@test "ci: phpunit exit 125 (no config file) is reported as SKIP and ci passes" {
  setup_ci
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 0
  assert_output_contains "No phpunit.xml or phpunit.xml.dist found, skipping PHPUnit."
  assert_summary_status "PHPUnit" "SKIP"
  assert_output_contains "ALL CHECKS PASSED"
}

@test "ci: existing phpunit.xml leads to PHPUnit OK" {
  setup_ci
  touch "$TESTDIR/project/phpunit.xml"
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 0
  assert_output_contains "PHPUNIT_ARGS: --configuration phpunit.xml"
  assert_summary_status "PHPUnit" "OK"
}

@test "ci: phpunit test failure (exit 1) is reported as FAILED and fails ci" {
  setup_ci
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TESTDIR/ddev-commands/web/phpunit"
  chmod +x "$TESTDIR/ddev-commands/web/phpunit"
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 1
  assert_output_contains "PHPUnit tests failed."
  assert_summary_status "PHPUnit" "FAILED"
}

@test "ci: phpunit not installed (exit 127) is reported as SKIP" {
  setup_ci
  printf '#!/usr/bin/env bash\nexit 127\n' > "$TESTDIR/ddev-commands/web/phpunit"
  chmod +x "$TESTDIR/ddev-commands/web/phpunit"
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 0
  assert_output_contains "PHPUnit is not installed, skipping."
  assert_summary_status "PHPUnit" "SKIP"
}

@test "ci: valid composer.json shows Composer validate OK" {
  setup_ci
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TESTDIR/ddev-commands/web/composer-validate"
  chmod +x "$TESTDIR/ddev-commands/web/composer-validate"
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 0
  assert_output_contains "Composer validate OK"
  assert_summary_status "Composer validate" "OK"
}

@test "ci: composer validation failure (exit 1) fails ci" {
  setup_ci
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TESTDIR/ddev-commands/web/composer-validate"
  chmod +x "$TESTDIR/ddev-commands/web/composer-validate"
  cd "$TESTDIR/project"
  run bash "$TESTDIR/ci"
  assert_status 1
  assert_output_contains "composer.json is invalid. Please fix the reported issues"
  assert_summary_status "Composer validate" "FAILED"
}
