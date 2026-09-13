namespace ModConductor.Engine

open ModConductor.Bethesda
open ModConductor.Protocol.V1

type BethesdaPluginService(plugins: PluginSession) =
    inherit BethesdaPlugins.BethesdaPluginsBase()

    override _.ScanPlugins(request, context) =
        task {
            let! result =
                plugins.Scan(ModLibraryWire.id request.ProfileId, context.CancellationToken)

            return BethesdaPluginWire.reply result
        }

    override _.ReadPlugins(request, _) =
        task {
            let! result = plugins.Read(ModLibraryWire.id request.SnapshotId)
            return BethesdaPluginWire.reply result
        }
