@echo off
setlocal
if not defined RELIEF_PYTHON set "RELIEF_PYTHON=python"
"%RELIEF_PYTHON%" "%~dp0tools\build_landscape.py"
if errorlevel 1 (
    echo Echec. Cet outil demande Python avec NumPy. Definissez RELIEF_PYTHON si necessaire.
    pause
    exit /b 1
)
echo Relief recalcule. Dans Godot, selectionnez Terrain puis Recharger le relief.
pause
