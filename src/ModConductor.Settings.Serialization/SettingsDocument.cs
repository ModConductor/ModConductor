using System;
using System.Text.Json.Serialization;
using Tomlyn;
using Tomlyn.Serialization;

namespace ModConductor.Settings.Serialization;

public sealed class SettingsDocument
{
  [JsonPropertyName("version")]
  public long Version { get; set; }

  [JsonPropertyName("presentation")]
  public PresentationDocument? Presentation { get; set; }
}

public sealed class PresentationDocument
{
  [JsonPropertyName("appearance")]
  public string Appearance { get; set; } = "system";

  [JsonPropertyName("text_scale")]
  public double TextScale { get; set; } = 1.0;

  [JsonPropertyName("interface_scale")]
  public double InterfaceScale { get; set; } = 1.0;

  [JsonPropertyName("contrast")]
  public string Contrast { get; set; } = "system";
}

[TomlSourceGenerationOptions(
  WriteIndented = true,
  MaxDepth = 4,
  DuplicateKeyHandling = TomlDuplicateKeyHandling.Error
)]
[TomlSerializable(typeof(SettingsDocument))]
internal partial class SettingsTomlContext : TomlSerializerContext;

public static class SettingsToml
{
  static SettingsToml() =>
    AppContext.SetSwitch("Tomlyn.TomlSerializer.IsReflectionEnabledByDefault", false);

  public static SettingsDocument Deserialize(string text) =>
    TomlSerializer.Deserialize(text, SettingsTomlContext.Default.SettingsDocument)
    ?? throw new TomlException("The settings document is empty.");

  public static string Serialize(SettingsDocument document) =>
    TomlSerializer.Serialize(document, SettingsTomlContext.Default.SettingsDocument);
}
