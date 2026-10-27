@echo off
rem ===========================================================================
rem  gmpub-tool - a menu for packaging and publishing Garry's Mod addons to the
rem  Steam Workshop with GMod's own gmad.exe and gmpublish.exe.
rem  Works for any addon. https://github.com/kgx96/gmpub-tool
rem  Copyright (c) 2026 KGX PRODUCTIONS. MIT License (see LICENSE).
rem ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion
set "TOOLVER=1.0.0"
set "REPO=https://github.com/kgx96/gmpub-tool"
title gmpub-tool %TOOLVER%

rem Everything the tool keeps lives next to this file.
set "HERE=%~dp0"
set "CFG=%HERE%gmpub-tool.ini"
set "IDFILE=%HERE%gmpub-ids.txt"
set "BUILD=%HERE%build"
set "LOG=%TEMP%\gmpub-tool.log"

rem Workshop addon types and tags gmad accepts (addon.json).
set "TYPES=gamemode map weapon vehicle npc entity tool effects model servercontent"
set "TAGS=fun roleplay scenic movie realism cartoon water comic build"

call :LOADCFG
if not defined GMODDIR call :DETECT
if not defined GMODDIR call :ASKGMOD
if not defined GMODDIR (echo. & echo Garry's Mod was not found. Nothing to do. & pause & exit /b 1)
call :DEFAULTS
call :SAVECFG
if not exist "%IDFILE%" type nul > "%IDFILE%"
if not exist "%BUILD%" mkdir "%BUILD%"
cd /d "!BIN!"

set "SEL="

:MAIN
cls
echo ===== gmpub-tool %TOOLVER% =====
call :STEAMCHECK
echo Garry's Mod : !GMODDIR!
echo Addons      : !ADDONS!
if defined SEL (echo Selected    : !SEL!) else (echo Selected    : none)
echo.
echo  1. List my published Workshop items
echo  2. Addons: show and select one
echo  3. Actions for the selected addon
echo  4. Update several addons in a row
echo  5. Open the addons folder
echo  S. Settings
echo  H. Help
echo  Q. Quit
echo.
set "CH="
set /p "CH=Choice: "
if /i "!CH!"=="1" goto LIST
if /i "!CH!"=="2" goto SELECT
if /i "!CH!"=="3" goto ACTIONS
if /i "!CH!"=="4" goto MULTI
if /i "!CH!"=="5" (start "" explorer "!ADDONS!" & goto MAIN)
if /i "!CH!"=="S" goto SETTINGS
if /i "!CH!"=="H" goto HELP
if /i "!CH!"=="Q" exit /b 0
goto MAIN

:LIST
echo.
"!BIN!\gmpublish.exe" list
echo.
pause
goto MAIN

:SELECT
call :DOSCAN
if "!COUNT!"=="0" (pause & goto MAIN)
echo.
set "PICK="
set /p "PICK=Number or folder name (blank = back): "
if not defined PICK goto MAIN
call :RESOLVE "!PICK!"
if not defined PICKED (echo No addon folder matches that. & pause & goto MAIN)
set "SEL=!PICKED!"
if not exist "!ADDONS!\!SEL!\addon.json" (
    echo.
    echo !SEL! has no addon.json. gmad needs one to package the folder.
    set "CONF="
    set /p "CONF=Create one now? (Y/N): "
    if /i "!CONF!"=="Y" call :MAKEJSON
)
goto ACTIONS

:ACTIONS
if not defined SEL (echo No addon selected. Use option 2 first. & pause & goto MAIN)
call :SETSEL "!SEL!"
cls
echo ===== !SEL! =====
echo Folder      : !SRC!
echo Package     : !GMA!
if defined SELID (echo Workshop ID : !SELID!) else (echo Workshop ID : none saved)
if exist "!SRC!\addon.json" (echo addon.json  : found) else (echo addon.json  : MISSING - use J to create it)
call :FINDNOTES
if defined NOTESFILE (echo Notes file  : !NOTESFILE!) else (echo Notes file  : none in !NOTESDIR!)
call :FINDICON
if defined ICONFILE (echo Icon        : !ICONFILE!) else (echo Icon        : none in !ICONDIR!)
echo.
echo  A. New       - check, package, publish as a NEW Workshop item
echo  B. Package   - check and build the .gma only
echo  C. Update    - check, package, update the existing Workshop item
echo  D. Set or change the saved Workshop ID
echo  E. Open the addon folder
echo  F. Upload a new icon for the existing Workshop item
echo  G. Open the Workshop page and its change notes
echo  J. Create or replace addon.json
echo  R. Back
echo.
set "CH="
set /p "CH=Choice: "
if /i "!CH!"=="A" (call :FLOWNEW & pause & goto ACTIONS)
if /i "!CH!"=="B" (call :PACKAGE & pause & goto ACTIONS)
if /i "!CH!"=="C" (call :FLOWUPDATE & pause & goto ACTIONS)
if /i "!CH!"=="D" (call :ASKID & pause & goto ACTIONS)
if /i "!CH!"=="E" (start "" explorer "!SRC!" & goto ACTIONS)
if /i "!CH!"=="F" (call :FLOWICON & pause & goto ACTIONS)
if /i "!CH!"=="G" (call :OPENPAGES & goto ACTIONS)
if /i "!CH!"=="J" (call :MAKEJSON & pause & goto ACTIONS)
if /i "!CH!"=="R" goto MAIN
goto ACTIONS

rem ===== Update several addons in a row =====

:MULTI
call :DOSCAN
if "!COUNT!"=="0" (pause & goto MAIN)
echo.
echo Enter the numbers (or folder names) to upload, in order, separated by spaces.
echo A folder name with spaces goes in quotes, e.g. 3 "my addon" 7
echo Addons with a saved ID are updated; the others are published as new items.
set "LISTIN="
set /p "LISTIN=Addons (blank = back): "
if not defined LISTIN goto MAIN
set "DONELIST="
set "SKIPLIST="
set "KEEPSEL=!SEL!"
for %%P in (!LISTIN!) do (
    call :MULTIONE "%%~P"
    if "!MULTIQUIT!"=="1" goto MULTIEND
)
:MULTIEND
set "SEL=!KEEPSEL!"
echo.
echo ===== Summary =====
if defined DONELIST (echo Uploaded :!DONELIST!) else (echo Uploaded : nothing)
if defined SKIPLIST echo Skipped  :!SKIPLIST!
echo Required Items, visibility and descriptions are set on each Workshop page.
pause
goto MAIN

:MULTIONE
set "MULTIQUIT=0"
set "MARG=%~1"
call :RESOLVE "!MARG!"
if not defined PICKED (echo [!MARG!] no such addon folder - skipped. & set "SKIPLIST=!SKIPLIST! !MARG!" & exit /b)
call :SETSEL "!PICKED!"
echo.
echo ---------------------------------------------------------------
if defined SELID (echo [!SEL!]  ID !SELID!  - update) else (echo [!SEL!]  no ID saved  - new item)
set "CONF="
set /p "CONF=Upload !SEL! now? (Y = yes, S = skip, Q = stop): "
if /i "!CONF!"=="Q" (set "MULTIQUIT=1" & exit /b)
if /i not "!CONF!"=="Y" (set "SKIPLIST=!SKIPLIST! !SEL!" & exit /b)
set "FLOWOK=0"
if defined SELID (call :FLOWUPDATE) else (call :FLOWNEW)
if "!FLOWOK!"=="1" (set "DONELIST=!DONELIST! !SEL!") else (set "SKIPLIST=!SKIPLIST! !SEL!")
exit /b

rem ===== Settings =====

:SETTINGS
cls
echo ===== Settings =====  (saved in !CFG!)
echo  1. Garry's Mod folder : !GMODDIR!
echo  2. Addons folder      : !ADDONS!
echo  3. Icons folder       : !ICONDIR!
echo  4. Notes folder       : !NOTESDIR!
echo  5. Find Garry's Mod again through Steam
echo  6. Edit the saved Workshop IDs  (!IDFILE!)
echo  R. Back
echo.
set "CH="
set /p "CH=Choice: "
if /i "!CH!"=="1" (call :ASKGMOD & call :DEFAULTS & call :SAVECFG & cd /d "!BIN!" & goto SETTINGS)
if /i "!CH!"=="2" (call :ASKDIR ADDONS "Addons folder" & call :SAVECFG & goto SETTINGS)
if /i "!CH!"=="3" (call :ASKDIR ICONDIR "Icons folder" & call :SAVECFG & goto SETTINGS)
if /i "!CH!"=="4" (call :ASKDIR NOTESDIR "Notes folder" & call :SAVECFG & goto SETTINGS)
if /i "!CH!"=="5" goto REDETECT
if /i "!CH!"=="6" (start "" notepad "!IDFILE!" & goto SETTINGS)
if /i "!CH!"=="R" goto MAIN
goto SETTINGS

:REDETECT
set "OLDGMOD=!GMODDIR!"
set "GMODDIR="
call :DETECT
if not defined GMODDIR (echo Not found through Steam. Kept: !OLDGMOD! & set "GMODDIR=!OLDGMOD!" & call :CHECKBIN & pause & goto SETTINGS)
set "ADDONS="
call :DEFAULTS
call :SAVECFG
cd /d "!BIN!"
echo Found: !GMODDIR!
pause
goto SETTINGS

:HELP
cls
echo ===== Help =====
echo Steam must be running and signed in to the account that owns the items.
echo.
echo Icons : put ^<addon folder name^>.jpg in the icons folder ^(512x512 JPG, under 1 MB^).
echo Notes : put ^<addon folder name^>.txt or ^<addon folder name^>_v^<version^>.txt in the notes folder.
echo         The first two lines become the one-line change notes gmpublish uploads;
echo         after an upload the full file can be opened to paste on the Workshop page.
echo IDs   : saved in gmpub-ids.txt as folder_name=ID, one per line.
echo Builds: .gma files go to the build folder next to this file.
echo.
echo Full guide and updates: %REPO%
echo.
set "CONF="
set /p "CONF=Open the guide in your browser? (Y/N): "
if /i "!CONF!"=="Y" start "" "%REPO%#readme"
goto MAIN

rem ===== Flows =====

:FLOWUPDATE
set "FLOWOK=0"
if not defined SELID (echo No Workshop ID saved for !SEL!. Use D to set it, or A to publish it as new. & exit /b)
call :PACKAGE
if "!PKGOK!"=="0" exit /b
call :NOTESLINE
echo.
echo Change notes ^(one line^):
echo   !CHANGES!
set "IN="
set /p "IN=Enter = use these, or type your own: "
if defined IN set "CHANGES=!IN:"='!"
rem (a trailing \ would escape the closing quote on gmpublish's command line)
if "!CHANGES:~-1!"=="\" set "CHANGES=!CHANGES!."
echo.
echo ===== Ready to update =====
echo   Addon   : !SEL!
echo   Item    : !SELID!
echo   Package : !GSIZE! bytes
echo   Notes   : !CHANGES!
set "CONF="
set /p "CONF=Upload to Workshop item !SELID!? (Y/N): "
if /i not "!CONF!"=="Y" (echo Not uploaded. & exit /b)
echo.
"!BIN!\gmpublish.exe" update -addon "!GMA!" -id "!SELID!" -changes "!CHANGES!"
set "GPERR=!errorlevel!"
if not "!GPERR!"=="0" (echo. & echo gmpublish ended with error code !GPERR!. Check its output above. & exit /b)
set "FLOWOK=1"
call :FULLNOTES
exit /b

:FLOWNEW
set "FLOWOK=0"
if defined SELID (
    echo !SEL! already has Workshop ID !SELID!. New makes a SEPARATE item.
    set "CONF="
    set /p "CONF=Type YES to publish a new item anyway: "
    if /i not "!CONF!"=="YES" exit /b
)
call :FINDICON
echo.
if defined ICONFILE (echo Icon: !ICONFILE!) else (echo No icon found as !ICONDIR!\!SEL!.jpg)
set "IN="
set /p "IN=Icon path (Enter = this one, or drag a JPG here): "
if defined IN set "ICONFILE=!IN:"=!"
call :CHECKICON
if "!ICONOK!"=="0" exit /b
call :PACKAGE
if "!PKGOK!"=="0" exit /b
echo.
echo ===== Ready to publish a NEW item =====
echo   Addon   : !SEL!
echo   Icon    : !ICONFILE!
echo   Package : !GSIZE! bytes
set "CONF="
set /p "CONF=Publish !SEL! as a new Workshop item? (Y/N): "
if /i not "!CONF!"=="Y" (echo Not published. & exit /b)
echo.
echo Uploading... gmpublish prints its output when it is done.
"!BIN!\gmpublish.exe" create -addon "!GMA!" -icon "!ICONFILE!" > "%LOG%" 2>&1
set "GPERR=!errorlevel!"
type "%LOG%"
call :FINDNEWID
echo.
if not "!GPERR!"=="0" if not defined NEWID (echo gmpublish ended with error code !GPERR!. Check its output above. & exit /b)
if defined NEWID (
    echo Workshop ID found in the output: !NEWID!
    set "IN="
    set /p "IN=Enter = save it, or type the correct ID: "
    if defined IN set "NEWID=!IN!"
) else (
    set /p "NEWID=Copy the new Workshop ID from the output above (blank = skip): "
)
if defined NEWID (
    call :SAVEID "!SEL!" "!NEWID!"
    call :GETID "!SEL!"
    set "SELID=!FOUNDID!"
)
set "FLOWOK=1"
echo On the Workshop page: check the visibility, write the description, add any Required Items.
if defined SELID (
    set "CONF="
    set /p "CONF=Open the Workshop page now? (Y/N): "
    if /i "!CONF!"=="Y" start "" "https://steamcommunity.com/sharedfiles/filedetails/?id=!SELID!"
)
exit /b

:FLOWICON
if not defined SELID (echo No Workshop ID saved for !SEL!. Use D to set it, or A to publish it as new. & exit /b)
call :FINDICON
echo.
echo Replaces the thumbnail of Workshop item !SELID!. The addon files are not uploaded.
if defined ICONFILE (echo Icon: !ICONFILE!) else (echo No icon found as !ICONDIR!\!SEL!.jpg)
set "IN="
set /p "IN=Icon path (Enter = this one, or drag a JPG here): "
if defined IN set "ICONFILE=!IN:"=!"
call :CHECKICON
if "!ICONOK!"=="0" exit /b
set "CONF="
set /p "CONF=Upload this icon to Workshop item !SELID!? (Y/N): "
if /i not "!CONF!"=="Y" exit /b
echo.
"!BIN!\gmpublish.exe" update -icon "!ICONFILE!" -id "!SELID!"
echo.
echo Steam can take a few minutes to show the new thumbnail.
exit /b

rem ===== Packaging =====

rem Checks addon.json, then runs gmad. If gmad refuses files (not on its
rem whitelist), they are listed and a retry with -warninvalid (skip them) is offered.
:PACKAGE
set "PKGOK=0"
set "GSIZE=0"
echo.
echo Checking !SEL! ...
if not exist "!SRC!\addon.json" (echo   addon.json is missing. Use J to create it. Nothing packaged. & exit /b)
findstr /c:"\"title\"" "!SRC!\addon.json" >nul || (echo   addon.json has no "title". Nothing packaged. & exit /b)
findstr /c:"\"type\"" "!SRC!\addon.json" >nul || (echo   addon.json has no "type". Nothing packaged. & exit /b)
set "FCOUNT=0"
for /f %%N in ('dir /s /b /a-d "!SRC!" 2^>nul ^| find /c /v ""') do set "FCOUNT=%%N"
echo   !FCOUNT! files in the folder.
set "WARNFLAG="
:PACKAGE_RUN
echo.
echo Packaging !SEL! ...
if exist "!GMA!" del /q "!GMA!"
"!BIN!\gmad.exe" create -folder "!SRC!" -out "!GMA!" !WARNFLAG! > "%LOG%" 2>&1
type "%LOG%"
echo.
if exist "!GMA!" goto PACKAGE_OK
findstr /i "whitelist" "%LOG%" >nul || (echo PACKAGE FAILED - see gmad's message above. Nothing was uploaded. & exit /b)
if defined WARNFLAG (echo PACKAGE FAILED. Nothing was uploaded. & exit /b)
echo These files are not allowed in a Workshop addon ^(gmad's whitelist^):
set "PREV="
for /f "usebackq delims=" %%L in ("%LOG%") do (
    set "CUR=%%L"
    if /i not "!CUR:whitelist=!"=="!CUR!" (
        if defined PREV echo   !PREV!
        echo   !CUR!
    )
    set "PREV=%%L"
)
echo Move them out of the folder, or add them to "ignore" in addon.json.
set "CONF="
set /p "CONF=Package anyway and leave these files out? (Y/N): "
if /i not "!CONF!"=="Y" (echo Nothing was uploaded. & exit /b)
set "WARNFLAG=-warninvalid"
goto PACKAGE_RUN
:PACKAGE_OK
for %%F in ("!GMA!") do set "GSIZE=%%~zF"
set "PKGOK=1"
echo Package OK: !GMA!  ^(!GSIZE! bytes^)
exit /b

rem ===== addon.json maker =====

:MAKEJSON
if exist "!ADDONS!\!SEL!\addon.json" (
    echo addon.json already exists in !SEL!.
    set "CONF="
    set /p "CONF=Replace it? The old one is kept as addon.json.bak (Y/N): "
    if /i not "!CONF!"=="Y" exit /b
)
echo.
set "JTITLE=!SEL!"
set "IN="
set /p "IN=Title (Enter = !SEL!): "
if defined IN set "JTITLE=!IN!"
set "JTITLE=!JTITLE:"='!"
set "JTITLE=!JTITLE:\=\\!"
echo.
echo Type:
set "N=0"
for %%T in (%TYPES%) do (
    set /a N+=1
    set "TYPE_!N!=%%T"
    echo   !N!. %%T
)
set "JTYPE="
set "IN="
set /p "IN=Number (Enter = tool): "
if defined IN set "IN=!IN:"=!"
if defined IN set "IN=!IN: =!"
if not defined IN set "JTYPE=tool"
if not defined JTYPE set "JTYPE=!TYPE_%IN%!"
if not defined JTYPE (echo Not a type number. Nothing written. & exit /b)
echo.
echo Tags ^(up to 2^):
set "N=0"
for %%T in (%TAGS%) do (
    set /a N+=1
    set "TAG_!N!=%%T"
    echo   !N!. %%T
)
set "IN="
set /p "IN=Numbers separated by a space (Enter = fun): "
if not defined IN set "IN=2BLANK"
set "JTAGS="
set "TCOUNT=0"
if "!IN!"=="2BLANK" (
    set "JTAGS="fun""
) else (
    for %%G in (!IN!) do (
        set "TG=!TAG_%%G!"
        if defined TG if !TCOUNT! LSS 2 (
            set /a TCOUNT+=1
            if defined JTAGS (set "JTAGS=!JTAGS!, "!TG!"") else (set "JTAGS="!TG!"")
        )
    )
)
if not defined JTAGS (echo No valid tag numbers. Nothing written. & exit /b)
if exist "!ADDONS!\!SEL!\addon.json" copy /y "!ADDONS!\!SEL!\addon.json" "!ADDONS!\!SEL!\addon.json.bak" >nul
> "!ADDONS!\!SEL!\addon.json" (
    echo {
    echo 	"title": "!JTITLE!",
    echo 	"type": "!JTYPE!",
    echo 	"tags": [!JTAGS!],
    echo 	"ignore": ["*.psd", "*.vcproj", "*.svn*", ".git*", "*.md", "*.bak"]
    echo }
)
echo.
echo Written: !ADDONS!\!SEL!\addon.json
type "!ADDONS!\!SEL!\addon.json"
exit /b

rem ===== Change notes =====

rem The notes file: <addon>.txt, else the newest <addon>_v*.txt, in NOTESDIR.
:FINDNOTES
set "NOTESFILE="
if exist "!NOTESDIR!\!SEL!.txt" (set "NOTESFILE=!NOTESDIR!\!SEL!.txt" & exit /b)
rem (a digit must follow "_v": kgx_core_vfx.txt belongs to another addon)
for /f "delims=" %%F in ('dir /b /a-d /o:-d "!NOTESDIR!\!SEL!_v*.txt" 2^>nul') do if not defined NOTESFILE (
    set "REST=%%~nF"
    set "P=!SEL!_v"
    for /l %%I in (1,1,260) do if defined P (set "P=!P:~1!" & set "REST=!REST:~1!")
    set "C=!REST:~0,1!"
    for %%D in (0 1 2 3 4 5 6 7 8 9) do if "!C!"=="%%D" set "NOTESFILE=!NOTESDIR!\%%F"
)
exit /b

rem One line for gmpublish: the notes file's first two lines without BBCode
rem (a list line is left out). Without a notes file: "Updated addon."
:NOTESLINE
set "CHANGES=Updated addon."
call :FINDNOTES
if not defined NOTESFILE exit /b
set "L1="
set "L2="
rem (non-empty lines to a temp file with delayed expansion off, then set /p:
rem the text keeps its ! " & characters)
set "NTMP=%TEMP%\gmpub-notes.tmp"
setlocal DisableDelayedExpansion
> "%NTMP%" (for /f "usebackq delims=" %%L in ("%NOTESFILE%") do echo(%%L)
endlocal
< "!NTMP!" (
    set /p "L1="
    set /p "L2="
)
del "!NTMP!" 2>nul
if not defined L1 exit /b
if defined L2 if /i "!L2:~0,5!"=="[list" set "L2="
if defined L2 if /i "!L2:~0,6!"=="[olist" set "L2="
if defined L2 if "!L2:~0,3!"=="[*]" set "L2="
for %%T in ("[h1]" "[/h1]" "[h2]" "[/h2]" "[h3]" "[/h3]" "[b]" "[/b]" "[i]" "[/i]" "[u]" "[/u]") do (
    set "L1=!L1:%%~T=!"
    if defined L2 set "L2=!L2:%%~T=!"
)
if defined L2 (set "CHANGES=!L1!: !L2!") else (set "CHANGES=!L1!")
set "CHANGES=!CHANGES:"='!"
if "!CHANGES:~-1!"=="\" set "CHANGES=!CHANGES!."
exit /b

rem After an update: the full notes in Notepad and the item's change notes page.
:FULLNOTES
if not defined SELID exit /b
call :FINDNOTES
if not defined NOTESFILE exit /b
echo.
echo gmpublish uploaded one line. To post the full notes: copy them from Notepad,
echo then on the change notes page click Edit on the newest entry and paste.
set "CONF="
set /p "CONF=Open the notes file and the change notes page? (Y/N): "
if /i not "!CONF!"=="Y" exit /b
start "" notepad "!NOTESFILE!"
start "" "https://steamcommunity.com/sharedfiles/filedetails/changelog/!SELID!"
exit /b

rem ===== Small helpers =====

:SETSEL
set "SEL=%~1"
call :GETID "!SEL!"
set "SELID=!FOUNDID!"
set "SRC=!ADDONS!\!SEL!"
set "GMA=!BUILD!\!SEL!.gma"
exit /b

:DOSCAN
for /f "delims==" %%V in ('set ADDON_ 2^>nul') do set "%%V="
set "COUNT=0"
echo.
echo Addons in !ADDONS!
echo.
for /d %%D in ("!ADDONS!\*") do (
    set /a COUNT+=1
    set "ADDON_!COUNT!=%%~nxD"
    call :GETID "%%~nxD"
    set "MARK="
    if not exist "%%D\addon.json" set "MARK=  [no addon.json]"
    if defined FOUNDID (echo   !COUNT!. %%~nxD   [ID !FOUNDID!]!MARK!) else (echo   !COUNT!. %%~nxD!MARK!)
)
if "!COUNT!"=="0" echo   No folders found. Check the addons folder in Settings.
exit /b

rem A number from the last list, or a folder name -> PICKED.
:RESOLVE
set "PICKED="
set "RP=%~1"
if not defined RP exit /b
set "RP=!RP:"=!"
set "PICKED=!ADDON_%RP%!"
if not defined PICKED if exist "!ADDONS!\!RP!\" set "PICKED=!RP!"
exit /b

:GETID
set "FOUNDID="
if not exist "%IDFILE%" exit /b
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%IDFILE%") do if /i "%%A"=="%~1" set "FOUNDID=%%B"
exit /b

:ASKID
echo.
set "NEWID="
set /p "NEWID=Workshop ID for !SEL! (blank = cancel): "
if not defined NEWID exit /b
call :SAVEID "!SEL!" "!NEWID!"
call :GETID "!SEL!"
set "SELID=!FOUNDID!"
exit /b

:SAVEID
set "SID=%~2"
set "SID=!SID: =!"
set "BADID="
if not defined SID set "BADID=1"
rem (digits only: remove every digit; anything left = not an ID. No pipe:
rem the two sides of a pipe run without delayed expansion)
set "TESTD=!SID!"
for %%D in (0 1 2 3 4 5 6 7 8 9) do if defined TESTD set "TESTD=!TESTD:%%D=!"
if defined TESTD set "BADID=1"
if defined BADID (echo Not saved: a Workshop ID is numbers only. & exit /b)
set "TMPF=%IDFILE%.tmp"
set "SNAME=%~1"
rem (the new line first: an edited file whose last line has no line break
rem cannot join it)
> "%TMPF%" (
    echo(!SNAME!=!SID!
    if exist "%IDFILE%" findstr /v /l /i /b /c:"!SNAME!=" "%IDFILE%"
)
move /y "%TMPF%" "%IDFILE%" >nul
echo Saved: !SNAME!=!SID!
exit /b

rem gmpublish create prints the new item's ID; take the last number of
rem 9 or more digits in its output as a suggestion (the user confirms it).
:FINDNEWID
set "NEWID="
for /f "usebackq delims=" %%L in ("%LOG%") do (
    for %%W in (%%L) do (
        set "W=%%~W"
        set "NONDIGIT="
        for /f "delims=0123456789" %%X in ("!W!") do set "NONDIGIT=1"
        if defined W if not defined NONDIGIT if not "!W:~8,1!"=="" set "NEWID=!W!"
    )
)
exit /b

:FINDICON
set "ICONFILE="
if exist "!ICONDIR!\!SEL!.jpg" (set "ICONFILE=!ICONDIR!\!SEL!.jpg" & exit /b)
if exist "!ICONDIR!\!SEL!.jpeg" set "ICONFILE=!ICONDIR!\!SEL!.jpeg"
exit /b

:CHECKICON
set "ICONOK=0"
if not defined ICONFILE (echo No icon given. A Workshop icon is a 512x512 JPG. & exit /b)
if not exist "!ICONFILE!" (echo Icon not found: !ICONFILE! & exit /b)
set "ICONEXT="
set "ICONSIZE=0"
for %%F in ("!ICONFILE!") do (set "ICONEXT=%%~xF" & set "ICONSIZE=%%~zF")
if /i not "!ICONEXT!"==".jpg" if /i not "!ICONEXT!"==".jpeg" (echo Not a JPG: !ICONFILE! & exit /b)
if !ICONSIZE! GTR 1048576 (echo The icon is over 1 MB ^(!ICONSIZE! bytes^); Steam refuses it. & exit /b)
set "ICONOK=1"
exit /b

:OPENPAGES
if not defined SELID (echo No Workshop ID saved for !SEL!. & pause & exit /b)
start "" "https://steamcommunity.com/sharedfiles/filedetails/?id=!SELID!"
start "" "https://steamcommunity.com/sharedfiles/filedetails/changelog/!SELID!"
exit /b

:STEAMCHECK
tasklist /fi "imagename eq steam.exe" 2>nul | find /i "steam.exe" >nul || echo WARNING: Steam is not running. Start it and sign in before uploading.
exit /b

rem ===== Settings: load, save, find Garry's Mod =====

:LOADCFG
set "GMODDIR="
set "ADDONS="
set "ICONDIR="
set "NOTESDIR="
if not exist "%CFG%" exit /b
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%CFG%") do (
    if /i "%%A"=="GMODDIR" set "GMODDIR=%%B"
    if /i "%%A"=="ADDONS" set "ADDONS=%%B"
    if /i "%%A"=="ICONDIR" set "ICONDIR=%%B"
    if /i "%%A"=="NOTESDIR" set "NOTESDIR=%%B"
)
if defined GMODDIR call :CHECKBIN
rem (a stale Garry's Mod path: find it again; keep a custom addons folder that still exists)
if not defined BIN (set "GMODDIR=" & if not exist "!ADDONS!\" set "ADDONS=")
exit /b

:SAVECFG
> "%CFG%" (
    echo # gmpub-tool settings. Change them in the Settings menu or here.
    echo GMODDIR=!GMODDIR!
    echo ADDONS=!ADDONS!
    echo ICONDIR=!ICONDIR!
    echo NOTESDIR=!NOTESDIR!
)
exit /b

:DEFAULTS
call :CHECKBIN
if not defined ADDONS set "ADDONS=!GMODDIR!\garrysmod\addons"
if not defined ICONDIR set "ICONDIR=%HERE%icons"
if not defined NOTESDIR set "NOTESDIR=%HERE%notes"
if not exist "!ICONDIR!" mkdir "!ICONDIR!"
if not exist "!NOTESDIR!" mkdir "!NOTESDIR!"
exit /b

rem BIN = the folder with gmad.exe and gmpublish.exe.
:CHECKBIN
set "BIN="
if exist "!GMODDIR!\bin\gmad.exe" if exist "!GMODDIR!\bin\gmpublish.exe" set "BIN=!GMODDIR!\bin"
if not defined BIN if exist "!GMODDIR!\bin\win64\gmad.exe" if exist "!GMODDIR!\bin\win64\gmpublish.exe" set "BIN=!GMODDIR!\bin\win64"
exit /b

rem Steam's folder from the registry, then every Steam library in libraryfolders.vdf.
:DETECT
echo Looking for Garry's Mod through Steam ...
set "STEAMDIR="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find /i "SteamPath"') do set "STEAMDIR=%%B"
if not defined STEAMDIR for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul ^| find /i "InstallPath"') do set "STEAMDIR=%%B"
if not defined STEAMDIR exit /b
set "STEAMDIR=!STEAMDIR:/=\!"
call :TRYLIB "!STEAMDIR!"
if defined GMODDIR exit /b
set "VDF=!STEAMDIR!\steamapps\libraryfolders.vdf"
if not exist "!VDF!" exit /b
for /f "usebackq delims=" %%L in (`findstr /c:"\"path\"" "!VDF!"`) do (
    if not defined GMODDIR (
        set "LIB=%%L"
        set "LIB=!LIB:"path"=!"
        set "LIB=!LIB:"=!"
        set "LIB=!LIB:	=!"
        for /f "tokens=* delims= " %%S in ("!LIB!") do set "LIB=%%S"
        set "LIB=!LIB:\\=\!"
        call :TRYLIB "!LIB!"
    )
)
exit /b

:TRYLIB
set "TRY=%~1\steamapps\common\GarrysMod"
set "OLD=!GMODDIR!"
set "GMODDIR=!TRY!"
call :CHECKBIN
if not defined BIN set "GMODDIR=!OLD!"
exit /b

:ASKGMOD
echo.
echo Garry's Mod folder, e.g. C:\Program Files ^(x86^)\Steam\steamapps\common\GarrysMod
set "IN="
set /p "IN=Path (drag the GarrysMod folder here, blank = cancel): "
if not defined IN exit /b
set "IN=!IN:"=!"
if "!IN:~-1!"=="\" set "IN=!IN:~0,-1!"
if /i "!IN:~-4!"=="\bin" set "IN=!IN:~0,-4!"
set "OLD=!GMODDIR!"
set "GMODDIR=!IN!"
call :CHECKBIN
if defined BIN (
    set "ADDONS="
    echo Found gmad.exe and gmpublish.exe in !BIN!
) else (
    echo gmad.exe and gmpublish.exe are not in !IN!\bin
    set "GMODDIR=!OLD!"
    call :CHECKBIN
)
exit /b

rem %1 = variable name, %2 = label
:ASKDIR
set "IN="
set /p "IN=%~2 (drag the folder here, blank = keep): "
if not defined IN exit /b
set "IN=!IN:"=!"
if "!IN:~-1!"=="\" set "IN=!IN:~0,-1!"
if not exist "!IN!\" (echo Folder not found: !IN! & pause & exit /b)
set "%~1=!IN!"
exit /b
