setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-silverstripe-tools
  mkdir -p $TESTDIR
  export PROJNAME=test-silverstripe-tools
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --project-type=php --docroot=public
  ddev start -y >/dev/null
}

teardown() {
  set -eu -o pipefail
  cd "${TESTDIR}" || true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd "${TESTDIR}"
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get "${DIR}"
  ddev restart -y
  # Verify command files and config exist
  [ -f .ddev/commands/web/build ]
  [ -f .ddev/commands/web/check-outdated-dependencies ]
  [ -f .ddev/commands/web/ci ]
  [ -f .ddev/commands/web/fix ]
  [ -f .ddev/commands/web/jack ]
  [ -f .ddev/commands/web/lint ]
  [ -f .ddev/commands/web/phpunit ]
  [ -f .ddev/commands/web/prettier ]
  [ -f .ddev/commands/web/rector ]
  [ -f .ddev/commands/web/sspak ]
  [ -f .ddev/commands/web/stan ]
  [ -f .ddev/commands/web/tinker ]
  [ -f .ddev/config.netwerkstatt-tools.yaml ]
}

@test "install from release" {
  set -eu -o pipefail
  cd "${TESTDIR}"
  echo "# ddev add-on get wernerkrauss/ddev-silverstripe-tools with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get wernerkrauss/ddev-silverstripe-tools
  ddev restart -y
  [ -f .ddev/commands/web/build ]
  [ -f .ddev/commands/web/ci ]
  [ -f .ddev/config.netwerkstatt-tools.yaml ]
}
