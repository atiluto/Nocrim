@echo off
setlocal DisableDelayedExpansion
pushd "%~dp0"
if errorlevel 1 goto folder_error

set "NOCRIM_PYTHON=python"
python --version >nul 2>&1
if not errorlevel 1 goto python_ready

set "NOCRIM_PYTHON=py -3"
py -3 --version >nul 2>&1
if errorlevel 1 goto python_error

:python_ready
echo.
echo Applying edited dialogue to Nocrim...
echo.
%NOCRIM_PYTHON% tools\compile_scenario.py
if errorlevel 1 goto compile_error

%NOCRIM_PYTHON% tools\compile_scenario.py --check
if errorlevel 1 goto verify_error

echo.
%NOCRIM_PYTHON% tools\compile_events.py
if errorlevel 1 goto compile_error
%NOCRIM_PYTHON% tools\compile_events.py --check
if errorlevel 1 goto verify_error

echo Dialogue applied successfully.
echo You can now test it with play.bat.
goto success

:python_error
echo.
echo Python 3 was not found.
echo Install Python 3 and run this file again.
goto failure

:compile_error
echo.
echo Dialogue could not be applied.
echo Fix the file, field, or scene ID shown above and run this file again.
goto failure

:verify_error
echo.
echo Dialogue was generated but verification failed.
goto failure

:folder_error
echo.
echo The project folder could not be opened.
goto failure_no_popd

:success
echo.
pause
popd
exit /b 0

:failure
popd

:failure_no_popd
echo.
pause
exit /b 1
