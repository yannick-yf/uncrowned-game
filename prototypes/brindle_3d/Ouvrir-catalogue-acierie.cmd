@echo off
setlocal
if defined GODOT if exist "%GODOT%" goto run
set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT%" goto run
for %%G in (godot.exe) do set "GODOT=%%~$PATH:G"
if defined GODOT goto run
echo Godot introuvable. Ouvrir project.godot dans Godot puis scenes/catalogue_acierie.tscn et F6.
pause
exit /b 1
:run
start "Catalogue acierie" "%GODOT%" --path "%~dp0." res://scenes/catalogue_acierie.tscn
