# ZLS-Overlay

This repository packages the precompiled binaries from each github release of [zls](https://zigtools.org/zls/).     
The binaries can be accessed through `packages.<version>`. e.g. `packages."0.15.0"`.    

## Usage

Include this repo as an input in your `flake.nix`.

```nix
{
  inputs.zls-overlay.url = "github:omega-800/zls-overlay";
}
```

To use a specific version of zls in e.g. your devShell, add one of the following:       
Using the `packages` output:    

```nix
# flake.nix
{
  outputs =
    { nixpkgs, zls-overlay, ... }:
    {
      devShells.x86_64-linux =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              zls-overlay.packages.x86_64-linux."0.15.0"
            ];
          };
        };
    };
}
```

Or by using the overlay:    

```nix
# flake.nix
{
  outputs =
    { nixpkgs, zls-overlay, ... }:
    {
      devShells.x86_64-linux =
        let
          pkgs = import nixpkgs { 
            system = "x86_64-linux"; 
            overlays = [ zig-overlay.overlays.default ];
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              zlspkgs."0.15.0"
            ];
          };
        };
    };
}
```
