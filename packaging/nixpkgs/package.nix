{
  pkgs,
  lib ? pkgs.lib,
  dotnet-sdk_10,
  flutter347,
  version ? "@PACKAGE_VERSION@",
}:
let
  src = pkgs.fetchFromGitHub {
    owner = "ModConductor";
    repo = "ModConductor";
    tag = "v${version}";
    hash = "@SOURCE_HASH@";
  };
  dotnet-sdk = dotnet-sdk_10;
  flutter = flutter347;
  sourceFor =
    directories: files:
    lib.cleanSourceWith {
      inherit src;
      filter =
        path: type:
        let
          relative = lib.removePrefix "${toString src}/" (toString path);
          top = builtins.head (lib.splitString "/" relative);
          name = builtins.baseNameOf path;
        in
        relative == ""
        || (
          builtins.elem top directories
          && !(builtins.elem name [
            ".git"
            ".tools"
            ".agent-workspace"
            ".dart_tool"
            "bin"
            "obj"
            "build"
            "target"
            ".gradle"
            ".pub-cache"
            "test"
            "integration_test"
          ])
        )
        || builtins.elem relative files;
    };
  engineSource =
    sourceFor
      [ "src" "contracts" ]
      [
        "Directory.Build.props"
        "Directory.Build.targets"
        "Directory.Packages.props"
        "NuGet.config"
        "global.json"
      ];
  uiSource = sourceFor [ "ui" "docs" "packaging" ] [ "LICENSE" ];
  helperSource = sourceFor [ "native" ] [ ];
  sourceRevision = "v${version}";
  sourceDate = 1;
  patchSdk = ''
    substituteInPlace global.json \
      --replace-fail '"version": "10.0.400"' '"version": "${dotnet-sdk.version}"'
  '';

  nugetCache = pkgs.stdenvNoCC.mkDerivation {
    pname = "modconductor-nuget-cache";
    inherit version;
    src = engineSource;
    nativeBuildInputs = [
      dotnet-sdk
      pkgs.cacert
    ];
    dontConfigureNuget = true;
    postPatch = patchSdk;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-YX79YqPd6NCgeuH5+92Uu6aLUjgJ89l9bYFjBNPLnA4=";
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
    inherit version;
    src = engineSource;
    nativeBuildInputs = with pkgs; [
      dotnet-sdk
      clang
      pkg-config
      patchelf
    ];
    dontConfigureNuget = true;
    postPatch = patchSdk;
    buildInputs = with pkgs; [
      zlib
      openssl
      icu
      libunwind
      libsecret
    ];
    configurePhase = ''
      runHook preConfigure
      export HOME="$TMPDIR/home"
      export DOTNET_CLI_HOME="$HOME"
      export NUGET_PACKAGES="$TMPDIR/nuget"
      mkdir -p "$HOME" "$NUGET_PACKAGES"
      cp -r ${nugetCache}/. "$NUGET_PACKAGES/"
      chmod -R u+w "$NUGET_PACKAGES"
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
        "$NUGET_PACKAGES/runtime.linux-x64.microsoft.dotnet.ilcompiler/10.0.11/tools/ilc"
      dotnet restore src/ModConductor.Engine/ModConductor.Engine.fsproj --locked-mode \
        --force --source ${emptyNugetFeed} -p:NuGetAudit=false
      runHook postConfigure
    '';
    buildPhase = ''
      runHook preBuild
      export LD_LIBRARY_PATH=${
        lib.makeLibraryPath [
          pkgs.openssl
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
        ]
      }
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
      runHook postInstall
    '';
    postFixup = ''
      patchelf --add-rpath ${
        lib.makeLibraryPath [
          pkgs.libsecret
          pkgs.glib
        ]
      } \
        "$out/lib/modconductor-engine/ModConductor.Engine"
    '';
    dontStrip = true;
    meta.platforms = [ "x86_64-linux" ];
  };

  lootHelper = pkgs.rustPlatform.buildRustPackage {
    pname = "modconductor-loot-helper";
    inherit version;
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
    inherit version;
    src = uiSource;
    sourceRoot = "source/ui";
    packageRoot = ".";
    pubspecLock = lib.importJSON ./pubspec.lock.json;
    flutterBuildFlags = [ "--no-pub" ];
    nativeBuildInputs = [
      pkgs.patchelf
      pkgs.jq
      pkgs.shared-mime-info
    ];
    preBuild = ''
      mkdir -p apps/mod_conductor/linux/flutter/ephemeral/.plugin_symlinks
      ln -s "$(packagePath file_selector_linux)" \
        apps/mod_conductor/linux/flutter/ephemeral/.plugin_symlinks/file_selector_linux
      cd apps/mod_conductor
    '';
    buildInputs = with pkgs; [
      gtk3
      libepoxy
      libx11
    ];
    extraWrapProgramArgs = "--prefix PATH : ${
      lib.makeBinPath [
        pkgs.glib.bin
        pkgs.xdg-utils
      ]
    } --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share --prefix XDG_DATA_DIRS : ${pkgs.adwaita-icon-theme}/share --prefix XDG_DATA_DIRS : ${pkgs.shared-mime-info}/share --set-default FONTCONFIG_FILE ${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
    postInstall = ''
      test -f "$out/app/modconductor/data/flutter_assets/NOTICES.Z"
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
      install -m644 ${uiSource}/LICENSE "$out/share/doc/modconductor/LICENSE"
      install -m644 ${uiSource}/docs/SOURCE.md "$out/share/doc/modconductor/SOURCE.md"
      cp -r ${uiSource}/docs/third-party "$out/share/doc/modconductor/"
      chmod u+w "$out/share/doc/modconductor/third-party"
      mkdir -p "$out/share/mime/packages"
      cp ${uiSource}/packaging/modconductor-profile.xml "$out/share/mime/packages/modconductor-profile.xml"
      update-mime-database "$out/share/mime"
      chmod u+w "$out/share/doc/modconductor/third-party/libloot-LICENSE.txt"
      cp ${liblootLicense} "$out/share/doc/modconductor/third-party/libloot-LICENSE.txt"
      for file in .config/flutter-sdk.json ui/pubspec.lock native/ModConductor.Loot.Helper/Cargo.lock; do
        install -Dm644 "${src}/$file" \
          "$out/share/doc/modconductor/dependency-manifests/$file"
      done
      substitute "${src}/global.json" \
        "$out/share/doc/modconductor/dependency-manifests/global.json" \
        --replace-fail '"version": "10.0.400"' '"version": "${dotnet-sdk.version}"'
      for file in ${src}/src/*/packages.lock.json ${src}/tests/*/packages.lock.json; do
        relative="''${file#${src}/}"
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
        bash ${src}/nix/write-package-metadata.sh \
          --output "$out" --version ${version} \
          --revision ${lib.escapeShellArg sourceRevision} \
          --source-date-epoch ${toString sourceDate} \
          --dotnet-sdk ${dotnet-sdk.version}
      }
      postFixupHooks+=(writeFinalPackageMetadata)
    '';
    postFixup = ''
      patchelf --add-rpath ${
        lib.makeLibraryPath [
          pkgs.libsecret
          pkgs.glib
        ]
      } \
        "$out/app/modconductor/engine/ModConductor.Engine"
      ln -s mod_conductor "$out/bin/modconductor"
    '';
    meta = {
      description = "Desktop mod organiser";
      homepage = "https://github.com/ModConductor/ModConductor";
      platforms = [ "x86_64-linux" ];
      mainProgram = "modconductor";
      license = lib.licenses.gpl3Plus;
      maintainers = [ ];
    };
    passthru = { inherit engine lootHelper; };
  };
in
app
