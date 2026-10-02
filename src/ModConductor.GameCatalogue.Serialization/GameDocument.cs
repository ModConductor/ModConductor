using System;
using System.Text.Json.Serialization;
using Tomlyn;
using Tomlyn.Serialization;

namespace ModConductor.GameCatalogue.Serialization;

public sealed class GameDocument
{
  [JsonPropertyName("id")]
  public string Id { get; set; } = "";

  [JsonPropertyName("revision")]
  public int Revision { get; set; } = 1;

  [JsonPropertyName("name")]
  public string Name { get; set; } = "";

  [JsonPropertyName("steam_app_id")]
  public uint SteamAppId { get; set; }

  [JsonPropertyName("mechanism")]
  public string Mechanism { get; set; } = "";

  [JsonPropertyName("executable")]
  public string Executable { get; set; } = "";

  [JsonPropertyName("linux_executable")]
  public string LinuxExecutable { get; set; } = "";

  [JsonPropertyName("content")]
  public string Content { get; set; } = "";

  [JsonPropertyName("windows_runtime")]
  public string WindowsRuntime { get; set; } = "";

  [JsonPropertyName("linux_runtime")]
  public string LinuxRuntime { get; set; } = "";

  [JsonPropertyName("metadata")]
  public string Metadata { get; set; } = "";

  [JsonPropertyName("unity_metadata")]
  public string UnityMetadata { get; set; } = "globalgamemanagers";

  [JsonPropertyName("linux_wrapper")]
  public string LinuxWrapper { get; set; } = "start_game_bepinex.sh";

  [JsonPropertyName("community")]
  public string Community { get; set; } = "";

  [JsonPropertyName("loader_namespace")]
  public string LoaderNamespace { get; set; } = "";

  [JsonPropertyName("loader_package")]
  public string LoaderPackage { get; set; } = "";

  [JsonPropertyName("loader_version")]
  public string LoaderVersion { get; set; } = "";

  [JsonPropertyName("archive_root")]
  public string ArchiveRoot { get; set; } = "";

  [JsonPropertyName("loader_page")]
  public string LoaderPage { get; set; } = "";

  [JsonPropertyName("loader_download")]
  public string LoaderDownload { get; set; } = "";

  [JsonPropertyName("loader_license")]
  public string LoaderLicense { get; set; } = "";

  [JsonPropertyName("proxy")]
  public string Proxy { get; set; } = "dwmapi.dll";

  [JsonPropertyName("core")]
  public string Core { get; set; } = "ue4ss";

  [JsonPropertyName("mods")]
  public string Mods { get; set; } = "ue4ss/Mods";

  [JsonPropertyName("settings_file")]
  public string SettingsFile { get; set; } = "ue4ss/UE4SS-settings.ini";

  [JsonPropertyName("log")]
  public string Log { get; set; } = "ue4ss/UE4SS.log";

  [JsonPropertyName("game_features")]
  public string GameFeatures { get; set; } = "";

  [JsonPropertyName("configs")]
  public string Configs { get; set; } = "";

  [JsonPropertyName("game_feature_field")]
  public string GameFeatureField { get; set; } = "GameFeature";

  [JsonPropertyName("arguments")]
  public string[] Arguments { get; set; } = [];

  [JsonPropertyName("excluded")]
  public string[] Excluded { get; set; } = [];
}

public sealed class CatalogueDocument
{
  [JsonPropertyName("games")]
  public GameDocument[] Games { get; set; } = [];
}

[TomlSourceGenerationOptions(
  WriteIndented = true,
  MaxDepth = 4,
  DuplicateKeyHandling = TomlDuplicateKeyHandling.Error
)]
[TomlSerializable(typeof(CatalogueDocument))]
internal partial class CatalogueTomlContext : TomlSerializerContext;

public static class CatalogueToml
{
  static CatalogueToml() =>
    AppContext.SetSwitch("Tomlyn.TomlSerializer.IsReflectionEnabledByDefault", false);

  public static CatalogueDocument Deserialize(string text) =>
    TomlSerializer.Deserialize(text, CatalogueTomlContext.Default.CatalogueDocument)
    ?? throw new TomlException("The game catalogue is empty.");

  public static string Serialize(CatalogueDocument document) =>
    TomlSerializer.Serialize(document, CatalogueTomlContext.Default.CatalogueDocument);
}
