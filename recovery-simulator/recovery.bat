@REM SPDX-FileCopyrightText: (c) 2022 ale5000
@REM SPDX-License-Identifier: GPL-3.0-or-later
@REM SPDX-FileType: SOURCE

@echo off
SETLOCAL 2> nul

REM Fix the working directory when using "Run as administrator"
IF "%CD%" == "%windir%\system32" CD /D "%~dp0"

SET "LANG=en_US.UTF-8"
SET "MAIN_DIR=%~dp0..\"

"%~dp0..\tools\win\busybox.exe" ash -- "%~dp0recovery.sh" %*

ENDLOCAL 2> nul
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%
