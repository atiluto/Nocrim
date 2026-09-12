@echo off
setlocal
cd /d "%~dp0"
if exist "MagentaCutoutTool.exe" (
  start "" "MagentaCutoutTool.exe"
  exit /b 0
)
python "tools\alpha_cutout_tool.py"
if errorlevel 1 (
  echo Failed to start. Use MagentaCutoutTool.exe from the portable ZIP,
  echo or install Python and the packages in tools\alpha_cutout_requirements.txt.
  pause
)
endlocal
