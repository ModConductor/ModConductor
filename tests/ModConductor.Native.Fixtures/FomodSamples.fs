namespace ModConductor.Native.Fixtures

open System.IO
open System.IO.Compression
open System.Text

module FomodSamples =
    let choices =
        """
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://qconsulting.ca/fo3/ModConfig5.0.xsd">
  <moduleName>Rivière textures</moduleName>
  <moduleDependencies operator="And">
    <gameDependency version="1.7"/>
    <fileDependency file="base.txt" state="Active"/>
    <fileDependency file="textures/inactive.dds" state="Inactive"/>
    <fileDependency file="absent.txt" state="Missing"/>
    <dependencies operator="Or"><fommDependency version="99"/><fileDependency file="base.txt" state="Active"/></dependencies>
  </moduleDependencies>
  <requiredInstallFiles><folder source="Core" destination=""/></requiredInstallFiles>
  <installSteps order="Explicit">
    <installStep name="Texture quality"><optionalFileGroups><group name="Texture quality" type="SelectExactlyOne"><plugins order="Explicit">
      <plugin name="2K textures"><description>Water textures at 2048 × 2048 pixels.</description><files><file source="Textures/2K/water.dds" destination="textures/water.dds" priority="10"/><file source="Textures/2K/water.dds" destination="textures/second.dds" priority="10"/></files><conditionFlags><flag name="quality">2k</flag></conditionFlags><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
      <plugin name="4K textures"><description>High resolution water.</description><files><file source="Textures/4K/water.dds" destination="textures/water.dds" priority="10"/></files><conditionFlags><flag name="quality">4k</flag></conditionFlags><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
    </plugins></group></optionalFileGroups></installStep>
    <installStep name="Patches"><visible><flagDependency flag="quality" value="2k"/></visible><optionalFileGroups order="Explicit">
      <group name="Water features" type="SelectAtLeastOne"><plugins order="Explicit">
        <plugin name="Waterfalls"><description>Enable waterfall foam.</description><conditionFlags><flag name="waterfalls">yes</flag></conditionFlags><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
        <plugin name="Riverbanks"><description>Bank meshes.</description><files><file source="banks.nif" destination="meshes/banks.nif"/></files><conditionFlags><flag name="banks">yes</flag></conditionFlags><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
      </plugins></group>
      <group name="Finish" type="SelectAtMostOne"><plugins order="Explicit">
        <plugin name="Normal"><description>Normal finish.</description><files><file source="normal.txt"/></files><typeDescriptor><dependencyType><defaultType name="Recommended"/><patterns><pattern><dependencies><fileDependency file="Unknown.esp" state="Active"/></dependencies><type name="Recommended"/></pattern></patterns></dependencyType></typeDescriptor></plugin>
        <plugin name="Gloss"><description>Gloss finish.</description><files><file source="gloss.txt"/></files><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
      </plugins></group>
      <group name="Core features" type="SelectAll"><plugins order="Explicit">
        <plugin name="Settings"><description>Required settings.</description><files><file source="settings.ini" destination="Riviere/settings.ini"/></files><typeDescriptor><type name="Required"/></typeDescriptor></plugin>
        <plugin name="Details"><description>Shared details.</description><files><file source="detail.dds" destination="textures/detail.dds"/></files><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
      </plugins></group>
      <group name="Compatibility" type="SelectAny"><plugins order="Explicit">
        <plugin name="Unavailable"><description>Do not select.</description><files><file source="not-present.txt" installIfUsable="true"/></files><typeDescriptor><type name="NotUsable"/></typeDescriptor></plugin>
        <plugin name="Optional compatibility"><description>Check requirements.</description><files><file source="usable.txt" installIfUsable="true"/><file source="always.txt" alwaysInstall="true"/></files><typeDescriptor><type name="CouldBeUsable"/></typeDescriptor></plugin>
      </plugins></group>
    </optionalFileGroups></installStep>
    <installStep name="Foam style"><visible><flagDependency flag="waterfalls" value="yes"/></visible><optionalFileGroups><group name="Foam style" type="SelectExactlyOne"><plugins order="Explicit">
      <plugin name="Soft foam"><description>Soft surface foam.</description><files><file source="soft.dds" destination="textures/foam.dds"/></files><typeDescriptor><type name="Recommended"/></typeDescriptor></plugin>
      <plugin name="Clear water"><description>No surface foam.</description><files><file source="clear.dds" destination="textures/foam.dds"/></files><typeDescriptor><type name="Optional"/></typeDescriptor></plugin>
    </plugins></group></optionalFileGroups></installStep>
  </installSteps>
  <conditionalFileInstalls><patterns><pattern><dependencies operator="And"><flagDependency flag="quality" value="2k"/><flagDependency flag="banks" value="yes"/></dependencies><files><file source="conditional.ini" destination="Riviere/patch.ini"/></files></pattern></patterns></conditionalFileInstalls>
</config>
"""

    let create path xml =
        use file = File.Create path
        use archive = new ZipArchive(file, ZipArchiveMode.Create)

        let write name value =
            use output = archive.CreateEntry("Package/" + name).Open()
            output.Write(Encoding.UTF8.GetBytes(value: string))

        write "fomod/ModuleConfig.xml" xml
        write "fomod/info.xml" "<fomod><Name>Metadata fallback</Name><Version>1.3</Version></fomod>"

        for name, value in
            [ "Core/textures/water.dds", "old"
              "Textures/2K/water.dds", "two-k"
              "Textures/4K/water.dds", "four-k"
              "banks.nif", "banks"
              "normal.txt", "normal"
              "gloss.txt", "gloss"
              "settings.ini", "settings"
              "detail.dds", "detail"
              "usable.txt", "usable"
              "always.txt", "always"
              "soft.dds", "soft"
              "clear.dds", "clear"
              "conditional.ini", "conditional" ] do
            write name value
