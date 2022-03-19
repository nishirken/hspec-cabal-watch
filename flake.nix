{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
    let
      packageName = "hspec-cabal-watch";
      execName = "hcw";
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          ${packageName} =
            final.haskell-nix.cabalProject' {
              src = ./.;
              compiler-nix-name = "ghc8107";
              shell = {
                tools = {
                  cabal = "3.6.2.0";
                  hlint = "latest";
                  haskell-language-server = "latest";
                  ormolu = "0.1.4.1";
                };
                buildInputs = [pkgs.haskellPackages.implicit-hie pkgs.entr];
                withHoogle = true;
              };
            };
          })
        ];
      flake = pkgs.${packageName}.flake {};
    in flake // {
      # Built by `nix build .`
      defaultPackage = (flake.packages."${packageName}:exe:${execName}".overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs or [] ++ [pkgs.makeWrapper];
        postInstall = oldAttrs.postInstall or "" + ''
          wrapProgram $out/bin/${execName} --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.entr]}
        '';
      }));
    });
  }
