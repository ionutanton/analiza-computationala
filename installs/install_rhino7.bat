@echo off
echo Scholarh 2024
echo Instalare pluginuri de grasshopper pentru analize urbane

REM Get the directory of the current batch file
set "BAT_DIR=%~dp0"

:::::::
echo Incep instalare Ladybug Tools...
"%BAT_DIR%plugins_release_PollinationGHInstaller-1.52.10.exe" --TargetDir "C:\Program Files\Pollination" --mode unattended --unattendedmodeui minimal
echo Am instalat ladybug tools!

:::::::
echo Incep instalare Radiance...
"%BAT_DIR%Radiance_b268408a_Windows.exe" /S
echo Am instalat Radiance!
REM Add Radiance to the PATH variable
echo Setare variabila PATH...
set PATH=%PATH%;C:\Radiance\bin
echo Radiance adaugat la PATH!

:::::::
echo Incep instalare DecodingSpaces...
REM Copy DecodingSpaces 2021.10.11 folder to %AppData%/Grasshopper/Libraries
xcopy "%BAT_DIR%DecodingSpaces 2021.10.11" "%AppData%\Grasshopper\Libraries\DecodingSpaces 2021.10.11" /S /E /I
echo Am instalat DecodingSpaces!

REM Unblock all .gha files in the DecodingSpaces folder
echo Unblock fisiere .gha...
for %%f in ("%AppData%\Grasshopper\Libraries\DecodingSpaces 2021.10.11\*.gha") do (
  echo Unblock fisier "%%f"
  echo.>%%f:Zone.Identifier
)
echo Unblock finalizat la fisiere .gha!

:::::::
echo Incep instalare EleFront...
REM Copy EleFront folder to %AppData%/Grasshopper/Libraries
xcopy "%BAT_DIR%EleFront" "%AppData%\Grasshopper\Libraries\EleFront" /S /E /I
echo Am instalat EleFront!

echo Am terminat instalarea.
echo Puteti inchide aceasta fereastra!
pause