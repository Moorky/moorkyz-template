@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0SetProjectType.ps1" %*
set "exitCode=%errorlevel%"
if "%~1"=="" (
  echo(
  pause
)
exit /b %exitCode%
