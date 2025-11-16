# ZLS-Overlay

This repository packages the precompiled binaries from each github releae of [zls](https://zigtools.org/zls/).     
The binaries can be accessed through `packages.<version>`. e.g. `packages."0.15.0"`.    

## Usage

```nix
# flake.nix
{
  inputs.zls-overlay.url = "github:omega-800/zls-overlay";

  outputs = { zls, ... }: {
    devShells
  };
}
```

