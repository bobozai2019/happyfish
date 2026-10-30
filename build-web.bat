@echo off
setlocal
cd /d "%~dp0"
"D:\godot\godot_master\bin\godot.windows.editor.x86_64.exe" --headless --path . --export-debug Web build/web/index.html
set "BUILD_EXIT=%errorlevel%"
exit /b %BUILD_EXIT%
