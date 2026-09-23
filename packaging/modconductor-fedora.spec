Name: modconductor
Version: %{mc_version}
Release: %{mc_release}.fc44
Summary: Desktop mod organiser
License: NOASSERTION
URL: https://github.com/alsi-lawr/ModConductor
BuildArch: x86_64
Requires: /usr/bin/gsettings
Requires: gtk3, libsecret, libglvnd-egl, libglvnd-gles
Requires: libicu, libunwind, openssl-libs
Requires: fontconfig, dejavu-sans-fonts, gsettings-desktop-schemas, xdg-utils

%description
Desktop mod organiser.

%prep

%build

%install
mkdir -p "%{buildroot}/usr/lib/modconductor" "%{buildroot}/usr/bin" "%{buildroot}/usr/share/applications" "%{buildroot}/usr/share/doc"
cp -a "%{mc_payload}/." "%{buildroot}/usr/lib/modconductor/"
install -m 755 "%{mc_launcher}" "%{buildroot}/usr/bin/modconductor"
install -m 644 "%{mc_desktop}" "%{buildroot}/usr/share/applications/dev.modconductor.mod_conductor.desktop"
ln -s ../../lib/modconductor/share/doc/modconductor "%{buildroot}/usr/share/doc/modconductor"

%files
/usr/bin/modconductor
/usr/lib/modconductor
/usr/share/applications/dev.modconductor.mod_conductor.desktop
/usr/share/doc/modconductor
