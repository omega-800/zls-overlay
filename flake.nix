{
  description = "Zls binaries";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, self }:
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
                  fi
                '';
                installPhase = ''
                  mkdir -p $out/bin
                  cp zls $out/bin/zls
                '';
              };
            }
          ) (builtins.filter (v: v.system == pkgs.system) sources)
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
    };
}
