namespace ModConductor.Nexus

open System
open System.Globalization

module NexusWebLinks =
    let fileDownload game (modId: int64) (fileId: int64) =
        Uri(
            "https://www.nexusmods.com/"
            + game
            + "/mods/"
            + modId.ToString(CultureInfo.InvariantCulture)
            + "?tab=files&file_id="
            + fileId.ToString(CultureInfo.InvariantCulture)
            + "&nmm=1"
        )
