@echo off
setlocal
if defined GODOT if exist "%GODOT%" goto run
set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT%" goto run
for %%G in (godot.exe) do set "GODOT=%%~$PATH:G"
if defined GODOT goto run
echo Godot not found. Open project.godot, launch the game, then Tab and L for the coastline.
pause
exit /b 1
:run
start "Littoral breton" "%GODOT%" --path "%~dp0." --script res://tools/review_coastline.gd
