namespace ModConductor.DeploymentGenerations

open System.Runtime.CompilerServices

[<assembly: InternalsVisibleTo("ModConductor.Persistence")>]
[<assembly: InternalsVisibleTo("ModConductor.Native.Fixtures")>]
[<assembly: InternalsVisibleTo("ModConductor.Deployment")>]
do ()
