let
  nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/eaad089433ca2bb662274377d33df3d0e51ef28b";
  rust-overlay = import (builtins.getFlake "github:oxalica/rust-overlay/9c72e6db1fc10cdb18e5ef01e31c1f4951e197e0");
  pkgs = import nixpkgs {
    system = builtins.currentSystem;
    overlays = [ rust-overlay ];
  };
in
pkgs.mkShellNoCC {
  packages = [
    (pkgs.rust-bin.stable."1.89.0".minimal.override {
      extensions = [ "rustfmt" ];
    })
  ];
}
