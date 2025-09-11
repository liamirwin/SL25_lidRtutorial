@echo off
setlocal

:: Prompt user for the input directory
set /p projectDir=Enter the path to the Quarto project directory: 

:: Check if directory exists
if not exist "%projectDir%" (
    echo The directory "%projectDir%" does not exist.
    pause
    exit /b 1
)

:: Run Quarto render
quarto render "%projectDir%" --to html --execute --log quarto_render.log

:: Inform user of completion
echo Done rendering project.
pause
