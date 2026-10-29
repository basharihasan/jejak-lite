@echo off
REM Windows helper — runs setup-env.ps1 (no Ruby). Works on Win10/11.
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-env.ps1" %*
exit /b %ERRORLEVEL%
