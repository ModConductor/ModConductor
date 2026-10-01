namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Threading
open ModConductor.Platform

module internal BethesdaArchive =
    open BethesdaArchiveCommon

    let tryOpen (source: Stream) digest (limits: ArchiveLimits) token =
        if not source.CanSeek then
            unsupported ()

        seek source 0L

        if source.Length < 4L then
            None
        else
            let magic = readBytes source 4 |> fourcc

            match magic with
            | "BSA\000" -> Some(BsaArchive.openContents source digest limits token)
            | "BTDX" -> Some(Ba2Archive.openContents source digest limits token)
            | "\000\001\000\000" -> Some(MorrowindArchive.openContents source digest limits token)
            | _ ->
                seek source 0L
                None

    let tryIdentify (source: Stream) =
        if not source.CanSeek then
            unsupported ()

        seek source 0L

        if source.Length < 8L then
            None
        else
            let magic = readBytes source 4 |> fourcc
            let version = u32 source

            match magic with
            | "BSA\000" when version = 103u || version = 104u || version = 105u ->
                Some("BSA v" + string version)
            | "BSA\000" -> unsupported ()
            | "\000\001\000\000" -> Some "BSA v256"
            | "BTDX" when
                (version = 1u || version = 2u || version = 3u || version = 7u || version = 8u)
                && source.Length >= 12L
                ->
                let kind = readBytes source 4 |> fourcc

                if kind = "GNRL" || kind = "DX10" then
                    Some("BA2 v" + string version + " " + kind)
                else
                    unsupported ()
            | "BTDX" -> unsupported ()
            | _ ->
                seek source 0L
                None
