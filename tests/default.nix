let
  srcs = import ../nix/srcs.nix;
in

{ pkgs ? srcs.pkgs
, makerpkgs ? srcs.makerpkgs
, nodepkgs ? srcs.nodepkgs
}@args:

let
  oracles = import ./.. args;
in

pkgs.mkShell rec {
  name = "oracle-smoke-test-shell";
  buildInputs = with pkgs; [
    procps jq mitmproxy
    go-ethereum

    nodepkgs.tap-xunit

    makerpkgs.dapp

    oracles.omnia
    oracles.install-omnia
  ] ++ oracles.omnia.runtimeDeps;

  RESULTS_DIR = "${toString ./.}/test-results";
  SMOKE_TEST = toString ./smoke/test;
  E2E_TEST = toString ./e2e/test;

  shellHook = ''
    xunit() {
      local name="$1"
      local output=$(mktemp tap-XXXXXXXX)
      tee "$output"
      mkdir -p "$RESULTS_DIR/$name"
      tap-xunit < "$output" \
        > "$RESULTS_DIR/$name/results.xml"
      rm -f "$output"
    }

    testSmoke() { "$SMOKE_TEST" | xunit smoke; }
    testE2E() { "$E2E_TEST" | xunit e2e; }
    updateE2E() { "$E2E_TEST" --update | xunit e2e-update; }
  '';
}
