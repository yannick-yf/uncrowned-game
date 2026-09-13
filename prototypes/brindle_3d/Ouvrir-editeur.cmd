@echo off
setlocal
set "MAP_GODOT=%GODOT%"
if not defined MAP_GODOT if exist "%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe" set "MAP_GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"
if not defined MAP_GODOT set "MAP_GODOT=godot"
start "" "%MAP_GODOT%" --editor --path "%~dp0." res://scenes/map_plate.tscn
