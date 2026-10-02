# Unity loaders

Unity Mono and Unity IL2CPP use separate declared backends. Valheim retains its
BepInEx 5.4.2333 Mono pack. The first IL2CPP declaration is Sons of the Forest
(Steam 1326470), targeting its x64 Windows client on Windows or a checked Proton
context on Linux. This does not promise arbitrary Unity titles or architectures.

The declared Windows pack is
[BepInExPack_IL2CPP 6.0.755](https://thunderstore.io/c/sons-of-the-forest/p/BepInEx/BepInExPack_IL2CPP/),
based on upstream `6.0.0-be.755+3fab71a`. Plugins must match that IL2CPP API.
BepInEx 5 plugins and earlier BepInEx 6 builds are not interchangeable with it.

The existing mod library also accepts compatible ordinary loader archives.
A loader is recognized by its declared package identity or standard backend core
path: `BepInEx/core/BepInEx.Unity.IL2CPP.dll` for IL2CPP, or
`BepInEx/core/BepInEx.Preloader.dll` for Mono. A single enclosing archive folder
is supported. Loader files deploy at the private game root; ordinary plugin
files deploy under `BepInEx/plugins`. Enabling and disabling use the same profile
loader control, settings editor, and log reader.

Declared native Linux x64 clients can use compatible ordinary archives and their
`run_bepinex.sh` wrapper. Sons of the Forest has no native Linux declaration;
its Windows pack is not a native Linux pack. Native Linux routing is covered by
fixtures, not a purchased-game runtime qualification.

## Runtime ownership

The loader, not Mod Conductor, downloads normal Unity base libraries, generates
interop assemblies, and decides when generated files can be reused. The normal
`BepInEx/config`, `cache`, `interop`, `unity-libs`, `dummy`, and loader log paths
use profile-owned `.mc-component-working` storage. Redeployment, disable/enable,
and profile switches do not write these files into the original game or immutable
mod payloads. User-configured external output paths remain user/dependency-owned.

The loader's CoreCLR files stay in the private game's `dotnet` directory, separate
from Mod Conductor's NativeAOT engine. Windows injection uses the pack's Doorstop
proxy. Proton uses a process-local `winhttp=n,b` override that preserves unrelated
Wine overrides. Native Linux loads Doorstop inside the selected runtime child.

Saves and global game settings are not managed for this declaration. Focused
synthetic fixtures verify binding, archive routing, launch descriptors, private
generated-file persistence, profile isolation, and removal. Actual game execution,
first-run generation, compatible plugin effects, and Windows/native Linux runtime
qualification require separate runtime checks.
