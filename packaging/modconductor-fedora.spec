Name: modconductor
Version: %{mc_version}
Release: %{mc_release}.fc44
Summary: Desktop mod organiser
# Bundled MC, Flutter/.NET, helper, xdelta3, and asset terms are retained under
# /usr/lib/modconductor/share/doc/modconductor/third-party. This is a local RPM,
# not an assertion that this bundled payload meets Fedora repository policy.
License: GPL-3.0-or-later AND GPL-3.0-only AND MPL-2.0 AND Apache-2.0 AND BSD-3-Clause AND BSD-2-Clause AND MIT AND 0BSD AND CC0-1.0 AND CC-BY-4.0 AND Unicode-3.0 AND Unicode-DFS-2016 AND Zlib AND BSL-1.0 AND FTL AND IJG
URL: https://github.com/alsi-lawr/ModConductor
BuildArch: x86_64
Requires: /usr/bin/gsettings
Requires: gtk3, libsecret, libglvnd-egl, libglvnd-gles
Requires: libicu, libunwind, openssl-libs
Requires: fontconfig, dejavu-sans-fonts, gsettings-desktop-schemas, xdg-utils, shared-mime-info

%description
Desktop mod organiser.

%prep

%build

%install
mkdir -p "%{buildroot}/usr/lib/modconductor" "%{buildroot}/usr/bin" "%{buildroot}/usr/share/applications" "%{buildroot}/usr/share/doc" "%{buildroot}/usr/share/icons"
cp -a "%{mc_payload}/." "%{buildroot}/usr/lib/modconductor/"
install -m 755 "%{mc_launcher}" "%{buildroot}/usr/bin/modconductor"
install -m 644 "%{mc_desktop}" "%{buildroot}/usr/share/applications/dev.modconductor.mod_conductor.desktop"
install -Dm 644 "%{mc_mime}" "%{buildroot}/usr/share/mime/packages/modconductor-profile.xml"
cp -a "%{mc_payload}/share/icons/hicolor" "%{buildroot}/usr/share/icons/"
ln -s ../../lib/modconductor/share/doc/modconductor "%{buildroot}/usr/share/doc/modconductor"

%files
/usr/bin/modconductor
/usr/lib/modconductor
/usr/share/applications/dev.modconductor.mod_conductor.desktop
/usr/share/mime/packages/modconductor-profile.xml
/usr/share/icons/hicolor/48x48/apps/dev.modconductor.mod_conductor.png
/usr/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png
/usr/share/doc/modconductor
