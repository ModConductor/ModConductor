namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Net
open System.Net.Http
open System.Text
open System.Threading.Tasks
open ModConductor.Thunderstore

type ThunderstoreHttpFixture(reply: HttpRequestMessage -> HttpResponseMessage) =
    inherit HttpMessageHandler()
    override _.SendAsync(request, _) = Task.FromResult(reply request)

module ThunderstoreSamples =
    let reference name version : VersionReference =
        { Package = {Community = "valheim"; Namespace = "Fixture"; Name = name}; Version = version }
    let jotunn = { Package = { Community = "valheim"; Namespace = "ValheimModding"; Name = "Jotunn" }; Version = "2.30.2" }
    let bep = { Package = { Community = "valheim"; Namespace = "denikson"; Name = "BepInExPack_Valheim" }; Version = "5.4.2333" }
    let dependency reference = { Reference = reference; Available = true; Icon = None }
    let package reference url bytes dependencies : PackageDetails =
        { Reference = reference; Description = "A supplied test package"; Icon = None; Deprecated = false
          Categories = []; Download = Uri url; Bytes = bytes
          Dependencies = dependencies; DependencyCount = dependencies.Length }
    let reader (packages: PackageDetails list) =
        { new IPackageReader with
            member _.Details(reference, version, _) =
                packages |> List.tryFind (fun package -> package.Reference.Package = reference && version = Some package.Reference.Version)
                |> Option.map Ok |> Option.defaultValue (Error(Problem.NotFound(PackageReference.label reference))) |> Task.FromResult
            member _.Search(_, _, _, _, _) = Task.FromResult(Error Problem.InvalidRequest)
            member _.Versions(_, _) = Task.FromResult(Error Problem.InvalidRequest) }
    let response status text =
        new HttpResponseMessage(status, Content = new StringContent(text, Encoding.UTF8, "application/json"))
    let search next name =
        """{"count":2,"next":NEXT,"results":[{"namespace":"Fixture","name":"NAME","description":"normal provider text","is_deprecated":false}]}"""
            .Replace("NEXT", next).Replace("NAME", name)
    let payload () =
        use bytes = new MemoryStream()
        do
            use zip = new ZipArchive(bytes, ZipArchiveMode.Create, true)
            use file = zip.CreateEntry("plugins\\Fixture.dll", CompressionLevel.NoCompression).Open()
            let content = Array.init (3 * 1024 * 1024) (fun n -> byte(n % 251))
            file.Write(content, 0, content.Length)
        bytes.ToArray()
