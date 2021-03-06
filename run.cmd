set VS_DIR=C:\VS
set SDK_DIR=C:\SDK

call :install_vs_build_tools
rem call :download_extract_windows_sdk

mkdir %SDK_DIR%

call :package_msvc_sdk
call :package_windows_sdk

for /d %%i in (%SDK_DIR%\*) do (
    rem arc archive %TRAVIS_BUILD_DIR%\msvc-%VCTOOLS_VERSION%-%%~nxi.tar.xz %%i
    7z a %TRAVIS_BUILD_DIR%\%%~nxi.zip %%i/*
)

goto :eof

rem dir /s /b "C:\Program Files (x86)\Windows Kits\10"
rem dir /s /b C:\VS
rem dir 

rem Installs VS Build Tools.
rem
rem Right now we just install all the default VC Tools workload.
rem
rem In the future we might want to be more selective about which workloads to include:
rem   Microsoft.VisualStudio.Component.Windows10SDK
rem   Microsoft.VisualStudio.Component.Windows10SDK.18362
rem   Microsoft.Component.VC.Runtime.UCRTSDK
rem   Microsoft.VisualStudio.Component.VC.Tools.x86.x64
rem
rem See all the available workloads here:
rem   https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019
rem   https://github.com/MicrosoftDocs/visualstudio-docs/blob/master/docs/install/includes/vs-2019/workload-component-id-vs-build-tools.md
rem
:install_vs_build_tools
    choco install visualstudio2019buildtools --package-parameters "--installPath %VS_DIR% --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --locale en-US" 
    goto :eof

:download_extract_windows_sdk
    choco install lessmsi

    set SDK=17763.132.181022-1834.rs5_release_svc_prod1_WindowsSDK.iso
    set SDK_URL= https://software-download.microsoft.com/download/sg/17763.132.181022-1834.rs5_release_svc_prod1_WindowsSDK.iso

    rem Download the Windows SDK ISO
    curl %SDK_URL% -o %SDK%

    rem Extract the Windows SDK ISO
    7z x -y *.iso -oISO

    rem Extract the SDK MSI archives using lessmsi
    mkdir SDK
    lessmsi x "ISO\Installers\Windows SDK Desktop Headers x86-x86_en-us.msi" SDK\
    lessmsi x "ISO\Installers\Windows SDK Desktop Libs x64-x86_en-us.msi" SDK\
    lessmsi x "ISO\Installers\Windows SDK Desktop Libs x86-x86_en-us.msi" SDK\
    lessmsi x "ISO\Installers\Universal CRT Headers Libraries and Sources-x86_en-us.msi" SDK\

    rem Remove some stuff we do not care about.
    rmdir /S /Q "SourceDir\Windows Kits\10\Catalogs\"
    rmdir /S /Q "SourceDir\Windows Kits\10\DesignTime\"
    rmdir /S /Q "SourceDir\Windows Kits\10\Lib\*\ucrt\arm\libucrt*.lib"

    goto :eof

:package_msvc_sdk
    set VCINSTALLDIR=%VS_DIR%\VC
    set /P VCTOOLS_VERSION=<"%VCINSTALLDIR%\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt"
    set PREFIX=MSVC_%VCTOOLS_VERSION%

    copy "%VCINSTALLDIR%\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt" "%SDK_DIR%" >NUL
    copy "%VCINSTALLDIR%\Auxiliary\Build\Microsoft.VCRedistVersion.default.txt" "%SDK_DIR%" >NUL

    xcopy "%VCINSTALLDIR%\Tools\MSVC\%VCTOOLS_VERSION%\crt" "%SDK_DIR%\%PREFIX%-crt" /s /e /h /y /i /k >NUL
    xcopy "%VCINSTALLDIR%\Tools\MSVC\%VCTOOLS_VERSION%\include" "%SDK_DIR%\%PREFIX%-include" /s /e /h /y /i /k >NUL
    xcopy "%VCINSTALLDIR%\Tools\MSVC\%VCTOOLS_VERSION%\lib" "%SDK_DIR%\%PREFIX%-lib" /s /e /h /y /i /k >NUL

    rem choco install archiver

    goto :eof

:package_windows_sdk
    set WINDOWS_SDK="C:\Program Files (x86)\Windows Kits\10"

    for /d %%i in (%WINDOWS_SDK%\Include\*) do (
        xcopy "%%i" "%SDK_DIR%\Windows_SDK_%%~nxi-includes" /s /e /h /y /i /k >NUL
    )

    for /d %%i in (%WINDOWS_SDK%\Lib\*) do (
        xcopy "%%i" "%SDK_DIR%\Windows_SDK_%%~nxi-lib" /s /e /h /y /i /k >NUL
    )

    goto :eof