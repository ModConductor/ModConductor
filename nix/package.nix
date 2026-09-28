{ self, pkgs, dotnet-sdk, flutter }:
let
  lib = pkgs.lib;
  sourceFor = directories: files: lib.cleanSourceWith {
    src = self.outPath;
    filter = path: type:
      let
        relative = lib.removePrefix "${toString self.outPath}/" (toString path);
        top = builtins.head (lib.splitString "/" relative);
        name = builtins.baseNameOf path;
      in
      relative == "" ||
      (builtins.elem top directories &&
        !(builtins.elem name [ ".git" ".tools" ".agent-workspace" ".dart_tool" "bin" "obj" "build" "target" ".gradle" ".pub-cache" "test" "integration_test" ])) ||
      builtins.elem relative files;
  };
  engineSource = sourceFor [ "src" "contracts" "third_party" ] [
    "Directory.Build.props" "Directory.Build.targets" "Directory.Packages.props"
    "NuGet.config" "global.json"
  ];
  uiSource = sourceFor [ "ui" "docs" "packaging" "third_party" ] [ ];
  helperSource = sourceFor [ "native" ] [ ];
  sourceRevision = if self ? rev then self.rev else if self ? dirtyRev then self.dirtyRev else "unknown";
  sourceDate = if self ? lastModified then self.lastModified else 0;

  nugetCache = pkgs.stdenvNoCC.mkDerivation {
    pname = "modconductor-nuget-cache";
    version = "0.1.0";
    src = engineSource;
    nativeBuildInputs = [ dotnet-sdk pkgs.cacert ];
    dontConfigureNuget = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-Rk6d2cQJCF3m4vpmDZ1fBo9tvxR+E2Sx6bE9Rrd8nuo=";
    configurePhase = ''
      export HOME="$TMPDIR/home"
      export DOTNET_CLI_HOME="$HOME"
      export NUGET_PACKAGES="$out"
      export NUGET_HTTP_CACHE_PATH="$TMPDIR/http-cache"
      mkdir -p "$HOME" "$NUGET_PACKAGES"
    '';
    buildPhase = ''
      dotnet restore src/ModConductor.Engine/ModConductor.Engine.fsproj \
        --locked-mode --force --no-cache -p:NuGetAudit=false
    '';
    installPhase = "true";
    dontFixup = true;
  };
  emptyNugetFeed = pkgs.runCommand "empty-nuget-feed" { } ''mkdir "$out"'';

  engine = pkgs.stdenv.mkDerivation {
    pname = "modconductor-engine";
    version = "0.1.0";
    src = engineSource;
    nativeBuildInputs = with pkgs; [ dotnet-sdk clang pkg-config patchelf ];
    dontConfigureNuget = true;
    buildInputs = with pkgs; [ zlib openssl icu libunwind libsecret ];
    configurePhase = ''
      runHook preConfigure
      export HOME="$TMPDIR/home"
      export DOTNET_CLI_HOME="$HOME"
      export NUGET_PACKAGES="$TMPDIR/nuget"
      mkdir -p "$HOME" "$NUGET_PACKAGES"
      cp -r ${nugetCache}/. "$NUGET_PACKAGES/"
      chmod -R u+w "$NUGET_PACKAGES"
      dotnet restore src/ModConductor.Engine/ModConductor.Engine.fsproj --locked-mode \
        --force --source ${emptyNugetFeed} -p:NuGetAudit=false
      runHook postConfigure
    '';
    buildPhase = ''
      runHook preBuild
      dotnet publish src/ModConductor.Engine/ModConductor.Engine.fsproj \
        -c Release -r linux-x64 --self-contained --no-restore \
        -p:ModConductorLocalPublishVerificationOnly=true \
        -p:NuGetAudit=false -o publish
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/modconductor-engine"
      cp -r publish/. "$out/lib/modconductor-engine/"
      install -m755 third_party/xdelta3/xdelta3-linux-x64 "$out/lib/modconductor-engine/xdelta3"
      runHook postInstall
    '';
    postFixup = ''
      patchelf --add-rpath ${lib.makeLibraryPath [ pkgs.libsecret pkgs.glib ]} \
        "$out/lib/modconductor-engine/ModConductor.Engine"
    '';
    dontStrip = true;
    meta.platforms = [ "x86_64-linux" ];
  };

  lootHelper = pkgs.rustPlatform.buildRustPackage {
    pname = "modconductor-loot-helper";
    version = "0.1.0";
    src = helperSource;
    sourceRoot = "source/native/ModConductor.Loot.Helper";
    cargoLock = {
      lockFile = "${helperSource}/native/ModConductor.Loot.Helper/Cargo.lock";
      outputHashes."libloot-0.29.6" = "sha256-Pz13z0uQfTeo47NJORfZ8n8ucqZdoLVGNIsrf2+OOGA=";
    };
    doCheck = false;
    meta = {
      platforms = [ "x86_64-linux" ];
      license = lib.licenses.gpl3Plus;
    };
  };

  liblootLicense = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/loot/libloot/136f3983c3eec7d377f83a7e7e0b0129aa5c8fe1/LICENSE";
    hash = "sha256-jOtLnuWt7d5Hsx6XXB2QxzrSe2sWWh3NgMfFRetluQM=";
  };

  app = flutter.buildFlutterApplication {
    pname = "modconductor";
    version = "0.1.0";
    src = uiSource;
    sourceRoot = "source/ui";
    packageRoot = ".";
    pubspecLock = lib.importJSON ./pubspec.lock.json;
    flutterBuildFlags = [ "--no-pub" ];
    nativeBuildInputs = [ pkgs.patchelf pkgs.python3 pkgs.shared-mime-info ];
    preBuild = ''
      mkdir -p apps/mod_conductor/linux/flutter/ephemeral/.plugin_symlinks
      ln -s "$(packagePath file_selector_linux)" \
        apps/mod_conductor/linux/flutter/ephemeral/.plugin_symlinks/file_selector_linux
      cd apps/mod_conductor
    '';
    buildInputs = with pkgs; [ gtk3 libepoxy libx11 ];
    extraWrapProgramArgs = ''--prefix PATH : ${lib.makeBinPath [ pkgs.glib.bin pkgs.xdg-utils ]} --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share --prefix XDG_DATA_DIRS : ${pkgs.adwaita-icon-theme}/share --prefix XDG_DATA_DIRS : ${pkgs.shared-mime-info}/share --set-default FONTCONFIG_FILE ${pkgs.fontconfig.out}/etc/fonts/fonts.conf'';
    postInstall = ''
      mkdir -p "$out/app/modconductor/engine" "$out/share/applications" "$out/share/doc/modconductor"
      for size in 48 256; do
        mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
        cp ${uiSource}/packaging/icons/hicolor/''${size}x''${size}/apps/dev.modconductor.mod_conductor.png \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/"
      done
      cp ${engine}/lib/modconductor-engine/ModConductor.Engine \
        ${engine}/lib/modconductor-engine/libe_sqlite3.so \
        ${engine}/lib/modconductor-engine/ModConductor.Engine.staticwebassets.endpoints.json \
        "$out/app/modconductor/engine/"
      cp ${lootHelper}/bin/modconductor-loot-helper "$out/app/modconductor/engine/"
      cp ${engine}/lib/modconductor-engine/xdelta3 "$out/app/modconductor/engine/"
      cp -r ${uiSource}/docs/third-party "$out/share/doc/modconductor/"
      chmod u+w "$out/share/doc/modconductor/third-party"
      install -m644 ${uiSource}/third_party/xdelta3/LICENSE "$out/share/doc/modconductor/third-party/xdelta3-LICENSE.txt"
      install -m644 ${uiSource}/third_party/xdelta3/README.md "$out/share/doc/modconductor/third-party/xdelta3-README.md"
      mkdir -p "$out/share/mime/packages"
      cp ${uiSource}/packaging/modconductor-profile.xml "$out/share/mime/packages/modconductor-profile.xml"
      update-mime-database "$out/share/mime"
      chmod u+w "$out/share/doc/modconductor/third-party/libloot-LICENSE.txt"
      cp ${liblootLicense} "$out/share/doc/modconductor/third-party/libloot-LICENSE.txt"
      ln -s libloot-LICENSE.txt \
        "$out/share/doc/modconductor/third-party/modconductor-loot-helper-LICENSE.txt"
      for file in .config/flutter-sdk.json global.json ui/pubspec.lock native/ModConductor.Loot.Helper/Cargo.lock; do
        install -Dm644 "${self.outPath}/$file" \
          "$out/share/doc/modconductor/dependency-manifests/$file"
      done
      for file in ${self.outPath}/src/*/packages.lock.json ${self.outPath}/tests/*/packages.lock.json; do
        relative="''${file#${self.outPath}/}"
        install -Dm644 "$file" \
          "$out/share/doc/modconductor/dependency-manifests/$relative"
      done
      cat > "$out/share/applications/dev.modconductor.mod_conductor.desktop" <<EOF
      [Desktop Entry]
      Type=Application
      Name=Mod Conductor
      Exec=$out/bin/modconductor %u
      Icon=dev.modconductor.mod_conductor
      Categories=Game;Utility;
      MimeType=x-scheme-handler/nxm;application/x-modconductor-profile;
      Terminal=false
      EOF
      cd ../..
    '';
    preFixup = ''
      writeFinalPackageMetadata() {
        python3 ${self.outPath}/nix/write-package-metadata.py \
          --output "$out" --version 0.1.0 \
          --revision ${lib.escapeShellArg sourceRevision} \
          --source-date-epoch ${toString sourceDate}
      }
      postFixupHooks+=(writeFinalPackageMetadata)
    '';
    postFixup = ''
      patchelf --add-rpath ${lib.makeLibraryPath [ pkgs.libsecret pkgs.glib ]} \
        "$out/app/modconductor/engine/ModConductor.Engine"
      ln -s mod_conductor "$out/bin/modconductor"
    '';
    meta = {
      platforms = [ "x86_64-linux" ];
      mainProgram = "modconductor";
    };
  };
in {
  inherit engine lootHelper;
  modconductor = app;
  default = app;
}
