module ModConductor.Engine.Probe

open System.Runtime.CompilerServices
open System.Runtime.InteropServices
open ModConductor.Operations

let runtime sqliteVersion : RuntimeResult =
    { Architecture = RuntimeInformation.ProcessArchitecture.ToString()
      NativeAot = not RuntimeFeature.IsDynamicCodeSupported
      SqliteVersion = sqliteVersion }
