@echo off

SET "script_path=%~dp0"
SET "script_dir=%script_path:~0,-1%"

SET "vimrc_path=%HOME%\.vimrc"
SET "gvimrc_path=%HOME%\.gvimrc"

@echo on

del "%vimrc_path%" >nul 2>&1
del "%gvimrc_path%" >nul 2>&1

copy "%script_path%\..\config\vimrc" "%vimrc_path%"
copy "%script_path%\..\config\gvimrc" "%gvimrc_path%"

pause
