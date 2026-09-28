Unicode true
!define MUI_ICON "${APP_ICON}"
!define MUI_UNICON "${APP_ICON}"
!include "MUI2.nsh"
!include "LogicLib.nsh"

Name "Mod Conductor ${VERSION}"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\Mod Conductor"
InstallDirRegKey HKCU "Software\ModConductor" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma

Function .onInit
  SetShellVarContext current
FunctionEnd

Function un.onInit
  SetShellVarContext current
FunctionEnd

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  IfFileExists "$INSTDIR\Uninstall.exe" 0 install_files
  ExecWait '"$INSTDIR\Uninstall.exe" /S _?=$INSTDIR' $0
  ${If} $0 != 0
    Abort "The previous Mod Conductor installation could not be removed."
  ${EndIf}
  Delete "$INSTDIR\Uninstall.exe"

install_files:
  ClearErrors
  SetOutPath "$INSTDIR"
  IfErrors 0 +2
    Abort "The installation directory could not be created."
  ClearErrors
  File /r "${PAYLOAD}\*"
  IfErrors 0 +2
    Abort "The installation files could not be copied."
  CreateDirectory "$SMPROGRAMS\Mod Conductor"
  CreateShortcut "$SMPROGRAMS\Mod Conductor\Mod Conductor.lnk" "$INSTDIR\mod_conductor.exe"
  CreateShortcut "$DESKTOP\Mod Conductor.lnk" "$INSTDIR\mod_conductor.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateShortcut "$SMPROGRAMS\Mod Conductor\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\ModConductor" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "DisplayName" "Mod Conductor"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor" "NoRepair" 1
  WriteRegStr HKCU "Software\Classes\ModConductor.Profile" "" "Mod Conductor profile"
  WriteRegStr HKCU "Software\Classes\ModConductor.Profile\DefaultIcon" "" '"$INSTDIR\mod_conductor.exe",0'
  WriteRegStr HKCU "Software\Classes\ModConductor.Profile\shell\open\command" "" '"$INSTDIR\mod_conductor.exe" --profile "%1"'
  WriteRegStr HKCU "Software\Classes\.mcprof" "" "ModConductor.Profile"
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\Mod Conductor.lnk"
  Delete "$SMPROGRAMS\Mod Conductor\Mod Conductor.lnk"
  Delete "$SMPROGRAMS\Mod Conductor\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Mod Conductor"
  Delete "$INSTDIR\Uninstall.exe"
  !include "${UNINSTALL_FILES}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ModConductor"
  ReadRegStr $0 HKCU "Software\Classes\.mcprof" ""
  ${If} $0 == "ModConductor.Profile"
    DeleteRegKey HKCU "Software\Classes\.mcprof"
  ${EndIf}
  DeleteRegKey HKCU "Software\Classes\ModConductor.Profile"
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
  DeleteRegKey HKCU "Software\ModConductor"
SectionEnd
