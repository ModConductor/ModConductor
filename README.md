<div align="center">
  <img
    src="ui/packages/mc_ui_foundation/assets/brand/modconductor.svg"
    width="144"
    height="144"
    alt="Mod Conductor logo">
  <h1>Mod Conductor</h1>
  <p><strong>Native mod management for Linux and Windows.</strong></p>
</div>

Manage Skyrim Special Edition on Linux or Windows from the same native desktop
application. Mod Conductor handles Steam discovery, Proton integration,
downloads, installation, profiles, and load order.

## Install

Download Mod Conductor from the
[latest GitHub release](https://github.com/alsi-lawr/ModConductor/releases/latest).

| Platform | Packages |
| --- | --- |
| Windows | Installer, portable ZIP, WinGet, Scoop, Chocolatey |
| Debian and Ubuntu | `.deb` package |
| Fedora | `.rpm` package |
| Arch Linux | `modconductor-bin` AUR package |
| Other Linux distributions | AppImage or portable archive |
| NixOS and Nix | Flake package |
| Homebrew on Linux | Cask |

All packaged builds target x86-64.

### Windows

```console
winget install alsi-lawr.ModConductor
```

```console
choco install modconductor
```

The release page also provides an installer, a portable ZIP, and a Scoop
manifest.

### Debian and Ubuntu

Download the `.deb` package, then install it with APT:

```console
sudo apt install ./ModConductor_VERSION-1_amd64.deb
```

### Fedora

Download the `.rpm` package, then install it with DNF:

```console
sudo dnf install ./modconductor-VERSION-1.fc44.x86_64.rpm
```

### Arch Linux

```console
yay -S modconductor-bin
```

### Nix

Run Mod Conductor without installing it:

```console
nix run github:alsi-lawr/ModConductor#modconductor
```

Install it through your normal flake configuration if you want Nix to manage
the package.

### AppImage and portable archive

Download the AppImage or Linux archive from the release page. The AppImage runs
without installation:

```console
chmod +x modconductor-VERSION-linux-x64.AppImage
./modconductor-VERSION-linux-x64.AppImage
```

## Skyrim Special Edition

Mod Conductor supports:

- Steam installations on Windows;
- Steam and Proton installations on Linux;
- separate mod workspaces and profiles;
- mod enablement, priority, and file conflicts;
- local archives and Nexus Mod Manager links;
- Bethesda plugin ordering and LOOT;
- SKSE installation;
- ENBSeries installation from an author-provided archive;
- FNIS and profile-specific generated files;
- profile import and export.

Each workspace keeps one installed copy of a mod. Profiles record whether that
mod is enabled and where it belongs in the priority order.

## Build from source

See [BUILDING.md](docs/BUILDING.md) for Linux and Windows build instructions.

The desktop application uses Flutter. Its engine uses F#, .NET 10 NativeAOT,
gRPC, and Protocol Buffers.

## Documentation

- [Building](docs/BUILDING.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development policy](docs/DEVELOPMENT-POLICY.md)
- [Dependencies](docs/DEPENDENCIES.md)
- [Source and provenance](docs/SOURCE.md)

## License

Mod Conductor is licensed under
[GPL-3.0-or-later](LICENSE).
