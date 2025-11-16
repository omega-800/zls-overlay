{
  description = "Zls binaries";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, self }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
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
                  tar -xf $src
                '';
                installPhase = ''
                  mkdir -p $out/bin
                  cp zls $out/bin/zls
                '';
              };
            }
          ) (builtins.filter (v: v.arch == pkgs.system) sources)
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
