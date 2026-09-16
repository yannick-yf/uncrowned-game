@echo off
setlocal
if defined GODOT if exist "%GODOT%" goto run
set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT%" goto run
for %%G in (godot.exe) do set "GODOT=%%~$PATH:G"
if defined GODOT goto run
echo Ouvrir project.godot avec Godot 4.7.2, puis appuyer sur F5.
pause
exit /b 1
:run
start "Catalogue scierie" "%GODOT%" --path "%~dp0." res://scenes/catalogue_scierie.tscn
