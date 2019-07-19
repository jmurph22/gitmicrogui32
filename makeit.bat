@echo off

if not exist rsrc.rc goto over1
\masm32\bin\rc /v rsrc.rc
\masm32\bin\cvtres /machine:ix86 rsrc.res
 :over1
 
if exist "template.obj" del "gitmicrogui32.obj"
if exist "template.exe" del "gitmicrogui32.exe"

\masm32\bin\ml /c /coff "gitmicrogui32.asm"
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

\masm32\bin\Link /SUBSYSTEM:WINDOWS "gitmicrogui32.obj" rsrc.res
 if errorlevel 1 goto errlink

dir "gitmicrogui32.*"
goto TheEnd

:nores
 \masm32\bin\Link /SUBSYSTEM:WINDOWS "gitmicrogui32.obj"
 if errorlevel 1 goto errlink
dir "gitmicrogui32.*"
goto TheEnd

:errlink
 echo _
echo Link error
goto TheEnd

:errasm
 echo _
echo Assembly Error
goto TheEnd

:TheEnd

del *.obj
pause
