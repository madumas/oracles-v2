let
  inherit (builtins) map filter listToAttrs attrValues isString currentSystem;
  inherit (import sources.nixpkgs {}) pkgs;
  inherit (pkgs) fetchgit;
  inherit (pkgs.lib.strings) removePrefix;

  getName = x:
   let
     parse = drv: (builtins.parseDrvName drv).name;
   in if isString x
      then parse x
      else x.pname or (parse x.name);

  sources = import ./sources.nix;
  ssbServerPatches = ../ssb-server/patches;
in

rec {
  inherit pkgs;

  makerpkgs = import sources.makerpkgs {
    dapptoolsOverrides.default = ./dapptools.nix;
  };

  nodepkgs = let
    nodepkgs' = import ./nodepkgs.nix { inherit pkgs; };
    shortNames = listToAttrs (map
      (x: { name = removePrefix "node_" (getName x.name); value = x; })
      (attrValues nodepkgs')
    );
  in nodepkgs' // shortNames;

  ssb-server = nodepkgs.ssb-server.override {
    buildInputs = with pkgs; [ gnumake nodepkgs.node-gyp-build nodepkgs.patch-package ];
#    name = "ssb-server-${nodepkgs.ssb-server.version}-patched";
#    preBuild = ''
#      sed -i -e 's/"ssb-db": "\^20\.0\.1",/"ssb-db": "20.0.1",/g' ./package.json
#    '';
#    postInstall = ''
#      mkdir -p ./patches
#      cp ${ssbServerPatches}/*.patch ./patches
#      patch-package
#    '';
  };

  setzer-mcd = makerpkgs.callPackage sources.setzer-mcd {};

  stark-cli = makerpkgs.callPackage ../starkware {};

  omnia = makerpkgs.callPackage ../omnia { inherit ssb-server setzer-mcd stark-cli; };

  install-omnia = makerpkgs.callPackage ../systemd { inherit ssb-server omnia; };
}
