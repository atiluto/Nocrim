@echo off
setlocal
chcp 65001 >nul
pushd "%~dp0"
if errorlevel 1 exit /b 1
set "NOCRIM_ROOT=%CD%"
set "NOCRIM_ENGINE=%NOCRIM_ROOT%\.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%NOCRIM_ENGINE%" goto missing_engine
if not exist "%NOCRIM_ROOT%\godot\project.godot" goto missing_project
if not exist "%NOCRIM_ROOT%\.local" mkdir "%NOCRIM_ROOT%\.local"
set "APPDATA=%NOCRIM_ROOT%\.local\appdata"
set "LOCALAPPDATA=%NOCRIM_ROOT%\.local\localappdata"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%NOCRIM_ROOT%\.local\play-saves" mkdir "%NOCRIM_ROOT%\.local\play-saves"
if not exist "%NOCRIM_ROOT%\.tools\godot\_sc_" type nul > "%NOCRIM_ROOT%\.tools\godot\_sc_"
echo Preparing Nocrim - Godot source project...
"%NOCRIM_ENGINE%" --headless --editor --path "%NOCRIM_ROOT%\godot" --log-file "%NOCRIM_ROOT%\.local\import.log" --import --quit
if errorlevel 1 goto failed
echo Starting game. Saves: .local\play-saves
"%NOCRIM_ENGINE%" --path "%NOCRIM_ROOT%\godot" --log-file "%NOCRIM_ROOT%\.local\play.log" %* -- "--save-root=%NOCRIM_ROOT%\.local\play-saves"
if errorlevel 1 goto failed
popd
exit /b 0

:missing_engine
echo Godot is missing. Keep the .tools\godot folder beside this BAT.
goto failed

:missing_project
echo Project missing: godot\project.godot
goto failed

:failed
echo Could not start the game. See .local\import.log and .local\play.log.
pause
popd
exit /b 1
