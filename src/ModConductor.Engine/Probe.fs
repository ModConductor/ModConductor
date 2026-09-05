module ModConductor.Engine.Probe

open System.Runtime.CompilerServices
open System.Runtime.InteropServices

type Runtime =
    { Architecture: string
      NativeAot: bool }

type Subscription = { RequestId: string; Count: int }

type Tick =
    { RequestId: string
      Sequence: int
      Complete: bool }

let runtime () =
    { Architecture = RuntimeInformation.ProcessArchitecture.ToString()
      NativeAot = not RuntimeFeature.IsDynamicCodeSupported }

let ticks (subscription: Subscription) =
    seq {
        for sequence in 1 .. subscription.Count do
            yield
                { RequestId = subscription.RequestId
                  Sequence = sequence
                  Complete = sequence = subscription.Count }
    }
