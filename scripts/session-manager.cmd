@echo off
rem session-manager.cmd - execution-policy-proof entry for the PowerShell prompt.
rem Running the .ps1 directly is blocked by a Restricted execution policy; a .cmd
rem batch file is not subject to that policy. It calls the implementation with
rem -ExecutionPolicy Bypass and forwards all arguments verbatim.
rem   .\.claude\scripts\session-manager.cmd -save 3eee5beb
rem   .\.claude\scripts\session-manager.cmd -save . -Tags tag1,tag2
rem   .\.claude\scripts\session-manager.cmd -saved
rem   .\.claude\scripts\session-manager.cmd -grep keyword
rem %~dp0 is this .cmd's own folder (.claude\scripts\), same dir as the impl.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0session-manager-impl.ps1" %*
