# Bethesda games

Declared Unity loaders are documented in [UNITY.md](UNITY.md).

## Installation and profiles

Select a title in the profile setup form or the Game tab. Choose a discovered
installation or select its folder. On Linux, select the existing Proton context
or Wine executable and prefix. A profile can retain an incomplete installation
choice, but Play requires a checked launch context.

The engine catalogue supplies the title, store choices, artwork and capabilities.
The desktop does not maintain another catalogue. Artwork uses hosted Steam images.
Conversions without separate artwork use the normal fallback image.

Each profile has a separate runnable game folder. Original game assets remain
linked. Declared game-local settings and plugin lists use profile-owned files.
Tools that point into the installation use this runnable folder. External tools
retain their configured paths and normal same-user write access.

## Title rules

| Title | Plugin order | Archive formats | Saves |
| --- | --- | --- | --- |
| Fallout: New Vegas | Plain plugin list and owned file timestamps | BSA 104 | `.fos` and `.nvse` |
| Skyrim Special Edition | Starred plugin list, light plugins | BSA 105 | `.ess` and `.skse` |
| Fallout 3 | Plain plugin list and owned file timestamps | BSA 104 | `.fos` |
| Tale of Two Wastelands | New Vegas rules, required conversion plugins | BSA 104 | `.fos` and `.nvse` |
| Oblivion | Plain plugin list and owned file timestamps | BSA 103 | `.ess` and `.obse` |
| Nehrim | Oblivion rules, required conversion plugins | BSA 103 | `.ess` and `.obse` |
| Morrowind | `Morrowind.ini` Game Files and owned file timestamps | BSA 256 | `.ess` and `.mwse` |
| Skyrim | Plain plugin list, timestamps before executable version 1.4.26 | BSA 104 | `.ess` and `.skse` |
| Enderal | Plain plugin list, required conversion plugins | BSA 104 | `.ess` and `.skse` |
| Enderal Special Edition | Starred plugin list, required conversion plugins | BSA 105 | `.ess` and `.skse` |
| Skyrim VR | Starred list, light plugins only with SkyrimVRESL | BSA 105 | `.ess` and `.skse` |
| Fallout 4 | Starred list, light plugins, Custom.ini test-file override | BA2 1, 7, 8 | `.fos` and `.f4se` |
| Fallout 4 London | Fallout 4 rules and separate identity | BA2 1, 7, 8 | `.fos` and `.f4se` |
| Fallout 4 VR | Starred list, light plugins only with FalloutVRESL or Daytripper4 | BA2 1, 7, 8 | `.fos` and `.f4se` |
| Starfield | Starred list, light and medium plugins, paired blueprints, test-file override | BA2 1, 2, 3 | `.sfs` and `.sfse` |
| Fallout 76 | Starred list and Custom.ini archives | BA2 1, 7, 8 | No local saves |
| Oblivion Remastered | Plain plugin list in the nested Data folder | BSA 103 | `.sav` |

New Vegas offers Steam, GOG Windows, Epic Games and DRM-free Windows choices.
Skyrim Special Edition retains Steam, GOG Windows and DRM-free Windows choices.
The other entries currently use Steam installation discovery. These choices do
not promise every store or regional executable variant from MO2.

The profile saves switch retains its shared/private meaning. Morrowind links the
runnable folder's Saves directory to original Saves when the switch is off.
When the switch is on, it links to the private profile folder.

## Timestamp order

Only effective active plugins in timestamp-ordered games receive independent
copies. The engine uses standard .NET `File.Copy`. Linux can clone file data on a
supported filesystem. Other cases copy the file normally, including cross-filesystem
copies. Cancellation waits for the current file and stops before the next file.

The engine reuses a prior owned copy only when its source pin and requested
timestamp match. A reorder or changed source gets new backing. Original game
files, immutable mod payloads, earlier deployments and other profiles keep their
timestamps. Other assets remain linked. Reported copied bytes describe file
lengths, not measured physical allocation after a filesystem clone.

## Starfield Data and plugins

Starfield reads two Data folders. Runtime Documents/My Games/Starfield/Data takes
precedence over installation/Data. Enabled mods take precedence over both.
The checked Windows user or selected Proton/Wine prefix supplies runtime Documents.

Deployment switches that Documents Data location through the existing backup and
restore mechanism. It preserves preexisting files beside the target on the same
filesystem. Deactivation and profile changes restore those files. The installation
Data folder remains unchanged. A previously absent Documents Data folder can remain
empty after deactivation.

Documents `Starfield.ccc` takes precedence over the installation copy. Test-file
entries in Custom.ini override the plugin list and creation list. The engine then
refuses plugin-order edits and leaves the original plugin-list contents intact.
Paired blueprint plugins follow their main plugin and do not consume another slot.

## Oblivion Remastered components

Ordinary plugins and assets use the nested `ObvData/Data` folder. The normal mod
component routes also support `Paks`, `Movies`, `OBSE`, `UE4SS`, `GameSettings`,
`Root` and an explicit `OblivionRemastered` tree. These routes use the private
runnable folder, not the original installation. The game launches its nested
Win64 shipping executable. This does not install or validate third-party loaders.

## Capability limits and qualification

Save grouping and transfer use each title's extensions. Save metadata inspection
currently supports Skyrim Special Edition and New Vegas/Tale of Two Wastelands.
Other titles report unavailable metadata instead of using the Skyrim parser.
Automatic LOOT integration and managed SKSE/FNIS workflows remain specific to
Skyrim Special Edition. Other script extenders use ordinary generic tool setup.

BA2 general-file inspection supports the listed versions. BA2 v3 DX10 texture
inspection is unavailable because that format uses a different texture codec.
Archive deployment still treats those files as opaque assets.
Starfield ContentCatalog grouping metadata is not imported.

Isolated Linux fixtures exercise actual installation binding, library publication,
plugin activation, deployment, launch descriptors, profile switches and removal
for all 17 titles. They use synthetic executable and game files. They do not
prove purchased-game execution or game ownership. New Vegas is not installed on
the qualification host. Real title execution and Windows runtime checks remain
unverified. Windows source paths remain part of the supported implementation.
