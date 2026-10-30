@echo off
setlocal

set "GAME_EXE=%~dp0build\windows\happy_fish.exe"

if not exist "%GAME_EXE%" (
	echo Windows game build not found:
	echo %GAME_EXE%
	echo.
	echo Export the Windows Desktop build from Godot first.
	pause
	exit /b 1
)

start "Happy Fish" /D "%~dp0build\windows" "%GAME_EXE%"
exit /b 0
