@echo off
cls
echo === Compilando Blackjack 8086 ===

REM Ensamblar los .asm a .obj
tasm /zi src\main.asm
tasm /zi src\lib.asm
tasm /zi src\game.asm

IF ERRORLEVEL 1 GOTO ERR

REM Linkear los .obj a .exe
tlink /v main.obj+lib.obj+game.obj, blackjack.exe

IF ERRORLEVEL 1 GOTO ERR

echo.
echo Compilacion OK. Ejecuta: blackjack.exe
GOTO END

:ERR
echo.
echo *** Error en la compilacion o el link ***

:END
pause
