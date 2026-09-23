{
  description = "Mod Conductor Linux desktop build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6774f7bc253789b113a4f39285dc0fa100abeacc";
    nixpkgs-dotnet.url = "github:NixOS/nixpkgs/fb230d1646d7c577387fcbbf2866d10c69d1badd";
  };

  outputs = { self, nixpkgs, nixpkgs-dotnet }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      dotnetPkgs = import nixpkgs-dotnet { inherit system; };
      dotnet-sdk = dotnetPkgs.dotnet-sdk_10;
      flutter = pkgs.flutter347;
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          flutter
          cmake
          ninja
          pkg-config
          gtk3
          libepoxy
          libsecret
          libx11
          clang
          python3
          yq-go
          xvfb
          xauth
          xdotool
          dotnet-sdk
        ];
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        FLUTTER_SUPPRESS_ANALYTICS = "1";
        DART_SUPPRESS_ANALYTICS = "1";
      };

      packages.${system} = import ./nix/package.nix {
        inherit self pkgs dotnet-sdk flutter;
      };
      apps.${system} = {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/modconductor";
        };
        modconductor = self.apps.${system}.default;
      };
    };
}
