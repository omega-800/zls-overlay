{
  description = "Zls binaries";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      pre-commit-hooks,
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "riscv64-linux"
        "i686-linux"
        "aarch64-linux"
        "armv7a-linux"
        "loongarch64-linux"
        "powerpc64le-linux"
        "s390x-linux"
        "aarch64-windows"
        "x86_64-windows"
        "i686-windows"
      ];
      eachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config = { };
              overlays = [ ];
            }
          )
        );
      treefmt = eachSystem (
        pkgs:
        treefmt-nix.lib.evalModule pkgs (_: {
          projectRootFile = "flake.nix";
          programs = {
            mdformat.enable = true;
            nixfmt.enable = true;
            shellcheck.enable = false;
            shfmt.enable = true;
          };
        })
      );
    in
    {
      packages = eachSystem (
        pkgs:
        let
          sources = builtins.fromJSON (nixpkgs.lib.fileContents ./sources.json);
        in
        pkgs.lib.listToAttrs (
          map (
            {
              url,
              version,
              sha256,
              ...
            }:
            {
              name = version;
              value = pkgs.stdenv.mkDerivation {
                inherit version;
                pname = "zls";
                src = pkgs.fetchurl {
                  inherit url sha256;
                };
                dontConfigure = true;
                dontBuild = true;
                dontFixup = true;
                unpackPhase = ''
                  if [[ "$src" =~ \.zip$ ]]; then 
                    unzip$ "$src"
                  elif [[ "$src" =~ \.tar\.xz$ ]]; then 
                    tar -xf $src
                  elif [[ "$src" =~ \.tar\.gz$ ]]; then 
                    tar -xzf $src
                  else
                    printf "archive format not supported"
                    exit 1
                  fi
                '';
                installPhase = ''
                  mkdir -p "$out/bin"
                  file="$(find . -type f -name zls -exec grep -rIL . "{}" \;)"
                  if [ -e "$file" ]; then
                    cp "$file" "$out/bin"
                  else
                    printf "no binary found"
                    exit 1
                  fi
                '';
              };
            }
          ) (builtins.filter (v: v.system == pkgs.stdenv.hostPlatform.system) sources)
        )
      );

      overlays =
        let
          zls = _: prev: {
            zlspkgs = self.packages.${prev.system};
          };
        in
        {
          inherit zls;
          default = zls;
        };

      devShells = eachSystem (
        pkgs:
        let
          inherit (self.checks.${pkgs.stdenv.hostPlatform.system}) pre-commit-check;
          zls = pkgs.mkShellNoCC {
            inherit (pre-commit-check) shellHook;
            buildInputs = pre-commit-check.enabledPackages;
            packages = [ pkgs.jq ];
          };
        in
        {
          inherit zls;
          default = zls;
        }
      );

      apps = eachSystem (
        pkgs:
        let
          update-sources = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "update-sources";
                runtimeInputs = [ pkgs.jq ];
                text = ''${./create-sources.sh} "$(cat ./github-token.txt)" -fo ./sources.json'';
              }
            }/bin/update-sources";
          };
        in
        {
          inherit update-sources;
          default = update-sources;
        }
      );

      checks = eachSystem (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
          src = ./.;
          hooks.treefmt = {
            enable = true;
            packageOverrides.treefmt = treefmt.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper;
          };
        };
      });

      formatter = eachSystem (pkgs: treefmt.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);
    };
}
