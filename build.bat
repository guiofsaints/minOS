@echo off
REM NextUI Build Script for Windows
REM Automatiza o processo de build do NextUI

setlocal enabledelayedexpansion

REM Default values
set PLATFORM=tg5040
set BUILD_CORES=essential
set CLEAN_FIRST=false
set VERBOSE=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto start_build
if "%~1"=="-p" (
    set PLATFORM=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--platform" (
    set PLATFORM=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-c" (
    set BUILD_CORES=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--cores" (
    set BUILD_CORES=%~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-C" (
    set CLEAN_FIRST=true
    shift
    goto parse_args
)
if "%~1"=="--clean" (
    set CLEAN_FIRST=true
    shift
    goto parse_args
)
if "%~1"=="-v" (
    set VERBOSE=true
    shift
    goto parse_args
)
if "%~1"=="--verbose" (
    set VERBOSE=true
    shift
    goto parse_args
)
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

echo Unknown option: %~1
goto show_help

:show_help
echo NextUI Build Script
echo.
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   -p, --platform PLATFORM    Target platform (tg5040, desktop) [default: tg5040]
echo   -c, --cores TYPE           Core build type (none, essential, all) [default: essential]
echo   -C, --clean                Clean build directory first
echo   -v, --verbose              Verbose output
echo   -h, --help                 Show this help
echo.
echo Examples:
echo   %0                         # Build with essential cores
echo   %0 -c none                 # Build system only (no cores)
echo   %0 -c all                  # Build with all cores (may fail on some)
echo   %0 -C -v                   # Clean build with verbose output
goto :eof

:start_build
echo [INFO] NextUI Build Starting...
echo [INFO] Platform: %PLATFORM%
echo [INFO] Cores: %BUILD_CORES%
echo [INFO] Clean first: %CLEAN_FIRST%
echo [INFO] Verbose: %VERBOSE%

REM Set verbose flags
set MAKE_FLAGS=
if "%VERBOSE%"=="true" set MAKE_FLAGS=MAKEFLAGS=

REM Clean if requested
if "%CLEAN_FIRST%"=="true" (
    echo [INFO] Cleaning previous build...
    make clean PLATFORM=%PLATFORM% %MAKE_FLAGS%
)

REM Setup
echo [INFO] Setting up build environment...
make setup %MAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] Setup failed
    exit /b 1
)

REM Build main system
echo [INFO] Building main system...
make build PLATFORM=%PLATFORM% %MAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] Main build failed
    exit /b 1
)

REM Build cores based on option
if "%BUILD_CORES%"=="essential" (
    echo [INFO] Building essential cores...
    make build-essential-cores PLATFORM=%PLATFORM% %MAKE_FLAGS%
) else if "%BUILD_CORES%"=="all" (
    echo [INFO] Building all cores...
    make build-cores PLATFORM=%PLATFORM% %MAKE_FLAGS%
) else (
    echo [INFO] Skipping core build
)

REM System installation
echo [INFO] Installing system components...
make system PLATFORM=%PLATFORM% %MAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] System installation failed
    exit /b 1
)

REM Core installation
echo [INFO] Installing cores...
make cores PLATFORM=%PLATFORM% %MAKE_FLAGS%

REM Special processing
echo [INFO] Processing special components...
make special %MAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] Special processing failed
    exit /b 1
)

REM Package
echo [INFO] Creating packages...
make package %MAKE_FLAGS%
if errorlevel 1 (
    echo [ERROR] Packaging failed
    exit /b 1
)

REM Done
make done %MAKE_FLAGS%

echo [SUCCESS] Build completed successfully!

if exist "releases\*.zip" (
    echo [INFO] Release files created:
    dir /b releases\*.zip
)

echo [INFO] Build process finished.
