@echo off
setlocal
rem One step from a fresh copy to the running program; later runs repeat only what changed.
rem Details: .template\run\README.md. Other programs: RUN.cmd <project>, see moorkyz.config.json.
rem Windows PowerShell must not inherit module paths from a PowerShell 7 terminal.
set "PSModulePath="
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0.template\run\Run.ps1" %*
exit /b %errorlevel%
