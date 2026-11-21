# The warning about unmatched containers is printed by lib.warn, which an evaluation
# can't observe. So this runs a nested nix-instantiate on dev/oci-container-warning-host.nix
# and checks its stderr, like nixpkgs' lib/tests/test-with-nix.nix.
{
  self,
  pkgs,
  system,
}:
pkgs.runCommand "oci-container-warning-test" { nativeBuildInputs = [ pkgs.nix ]; } ''
  export TEST_ROOT=$(pwd)/test-tmp
  export HOME=$(mktemp -d)
  export NIX_BUILD_HOOK=
  export NIX_CONF_DIR=$TEST_ROOT/etc
  export NIX_LOCALSTATE_DIR=$TEST_ROOT/var
  export NIX_LOG_DIR=$TEST_ROOT/var/log/nix
  export NIX_STATE_DIR=$TEST_ROOT/var/nix
  export NIX_STORE_DIR=$TEST_ROOT/store
  export PAGER=cat
  nix-store --init

  # Evaluates an attribute of the host, with extra --arg flags, into stderr.txt
  evalHost() {
    attr=$1
    shift
    nix-instantiate --eval --strict --json ${./oci-container-warning-host.nix} \
      --argstr nixpkgs ${pkgs.path} --argstr topology ${self} --argstr system ${system} \
      "$@" -A "$attr" > /dev/null 2> stderr.txt || { cat stderr.txt; exit 1; }
  }
  fail() {
    echo "FAIL: $1"
    cat stderr.txt
    exit 1
  }

  echo "Checking the warning lists the unmatched container when the topology is evaluated..."
  evalHost config.topology.self.services
  grep -q "these OCI containers don't match any service" stderr.txt || fail "no warning"
  grep -q -- "- mystery (ghcr.io/example/mystery:1)" stderr.txt || fail "mystery not listed"
  if grep -q -- "- jellyfin" stderr.txt; then fail "matched container listed"; fi

  echo "Checking warnUnmatched = false silences it..."
  evalHost config.topology.self.services --arg warnUnmatched false
  if grep -q "OCI containers" stderr.txt; then fail "warning with warnUnmatched = false"; fi

  echo "Checking a hidden entry silences it..."
  evalHost config.topology.self.services --arg hideMystery true
  if grep -q "OCI containers" stderr.txt; then fail "warning for a container of a hidden entry"; fi

  echo "Checking the system's own evaluation doesn't print it..."
  evalHost config.system.build.toplevel.drvPath
  if grep -q "OCI containers" stderr.txt; then fail "warning when evaluating the system"; fi

  echo "ok" > $out
''
