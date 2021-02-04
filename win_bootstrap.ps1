
$global:cmakeToolChain = "Visual Studio 16 2019"
$global:dependencyFolder = "$PSScriptRoot\deps"
$global:reposFolder = "$global:dependencyFolder\repos"
$global:binFolder = "$global:dependencyFolder\bin"
$global:includeFolder = "$global:dependencyFolder\include"
$global:libFolder = "$global:dependencyFolder\lib"

Function Init-Build {
    # Remove-Item -r $global:dependencyFolder -fo # -ErrorAction 'SilentlyContinue'
    If ( -not (Test-Path $global:reposFolder -PathType Any) ) {
        mkdir $global:reposFolder # -ErrorAction 'SilentlyContinue'
    }
    If ( -not (Test-Path $global:binFolder -PathType Any) ) {
        mkdir $global:binFolder # -ErrorAction 'SilentlyContinue'
    }
    If ( -not (Test-Path $global:includeFolder -PathType Any) ) {
        mkdir $global:includeFolder # -ErrorAction 'SilentlyContinue'
    }
    If ( -not (Test-Path $global:libFolder -PathType Any) ) {
        mkdir $global:libFolder # -ErrorAction 'SilentlyContinue'
    }
}

Function Build-Boost {
    If ( -not (Test-Path '.\boost' -PathType Any) ) {
        git clone --depth 1 --recurse-submodules -b boost-1.74.0 https://github.com/boostorg/boost.git
        Push-Location ".\boost"
        .\bootstrap.bat
    } Else {
        Push-Location ".\boost"
        .\b2.exe --clean-all -n    
    }
    If ((Test-Path '..\zlib' -PathType Any) -And (Test-Path '..\libbzip2' -PathType Any)) {
        Rename-Item -Path ".\..\zlib\zconf.h.in" -NewName "zconf.h" -ErrorAction SilentlyContinue
        .\b2.exe link=static threading=multi address-model=64 runtime-link=shared install -s BZIP2_SOURCE="..\libbzip2" -s ZLIB_SOURCE="..\zlib" --prefix=.\build_boost
        Rename-Item -Path "..\zlib\zconf.h" -NewName "zconf.h.in" -ErrorAction SilentlyContinue
    } Else {
        Write-Output "Error: No Zlib and/or Libbzip2."
    }
    Push-Location ".\build_boost\include\boost*"
    Robocopy.exe ".\" "$global:includeFolder" * /E /Z
    Pop-Location
    Push-Location ".\build_boost\lib"
    Robocopy.exe ".\" "$global:libFolder" *.lib /Z
    Pop-Location
    Pop-Location
}


Function Build-uWebSockets {
    If ( -not (Test-Path '.\uWebSockets' -PathType Any) ) {
        git.exe clone --depth 1 -j4 https://github.com/uNetworking/uWebSockets.git
    }
    Push-Location ".\uWebSockets\src"
    Robocopy.exe ".\" "$global:includeFolder" * /E /Z
    Pop-Location
}

Function Build-uSockets {
    If ( -not (Test-Path '.\uSockets' -PathType Any) ) {
        git.exe clone --depth 1 -j4 https://github.com/uNetworking/uSockets.git
    }
    Push-Location ".\uSockets"
    Copy-Item -Path "..\..\..\win\uSockets.vcxproj" -Destination ".\" -ErrorAction 'SilentlyContinue'
    msbuild.exe  uSockets.vcxproj /t:Rebuild /p:Configuration=Debug /p:Platform=x64
    msbuild.exe  uSockets.vcxproj /t:Rebuild /p:Configuration=Release /p:Platform=x64
    Copy-Item -Path ".\x64\Debug\libuSocketsd.lib" -Destination "$global:libFolder" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path ".\x64\Release\libuSockets.lib" -Destination "$global:libFolder" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path ".\src\libusockets.h" -Destination "$global:includeFolder" -ErrorAction 'SilentlyContinue'
    Pop-Location
}

Function Build-LibUv {
    If ( -not (Test-Path '.\libuv' -PathType Any) ) {
        git.exe clone --depth 1 -j4 https://github.com/libuv/libuv.git
    }
    Push-Location ".\libuv"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    mkdir "$global:includeFolder\uv" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" ..
    cmake --build ./ --config Release --target uv_a
    cmake --build ./ --config Debug --target uv_a
    Copy-Item -Path ".\Debug\uv_a.lib" -Destination "$global:libFolder\uv_ad.lib" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path ".\Release\uv_a.lib" -Destination "$global:libFolder\uv_a.lib" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path "..\include\uv\*.h" -Destination "$global:includeFolder\uv" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path "..\include\*.h" -Destination "$global:includeFolder" -ErrorAction 'SilentlyContinue'
    Pop-Location
    Pop-Location
}

Function Build-CryptoPp {
    If ( -not (Test-Path '.\cryptopp' -PathType Any) ) {
        git.exe clone --depth 1 -j4 https://github.com/weidai11/cryptopp.git
    }
    Push-Location ".\cryptopp"
    $content = Get-Content -Path 'cryptlib.vcxproj'
    $content = $content -Replace '>MultiThreaded<', '>MultiThreadedDLL<'
    $content = $content -Replace '>MultiThreadedDebug<', '>MultiThreadedDebugDLL<'
    $content | Set-Content -Path  'cryptlib.vcxproj'
    mkdir "$global:includeFolder\cryptopp" -ErrorAction 'SilentlyContinue'
    msbuild.exe  cryptlib.vcxproj /t:Rebuild /p:Configuration=Debug /p:Platform=x64
    msbuild.exe  cryptlib.vcxproj /t:Rebuild /p:Configuration=Release /p:Platform=x64
    Copy-Item -Path ".\x64\Output\Debug\cryptlib.lib" -Destination "$global:libFolder\cryptlibd.lib" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path ".\x64\Output\Release\cryptlib.lib" -Destination "$global:libFolder\cryptlib.lib" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path "*.h" -Destination "$global:includeFolder\cryptopp" -ErrorAction 'SilentlyContinue'
    # Pop-Location
    Pop-Location
}

Function Build-CurlCpp {
    If ( -not (Test-Path '.\curlcpp' -PathType Any) ) {
        git.exe clone --depth 1 -j4 https://github.com/JosephP91/curlcpp.git
    }
    Push-Location ".\curlcpp"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" -DCURL_LIBRARY="$global:libFolder" -DCURL_INCLUDE_DIR="$global:includeFolder" ..
    cmake --build ./ --config Release --target curlcpp
    cmake --build ./ --config Debug --target curlcpp
    Copy-Item -Path ".\src\Release\curlcpp.lib" -Destination "$global:libFolder" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path ".\src\Debug\curlcpp.lib" -Destination "$global:libFolder\curlcppd.lib" -ErrorAction 'SilentlyContinue'
    Copy-Item -Path "..\include\*.h" -Destination "$global:includeFolder" -ErrorAction 'SilentlyContinue'
    Pop-Location
    Pop-Location
}

Function Build-Curl {
    If ( -not (Test-Path '.\curl' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/curl/curl.git
    }
    Rename-Item -Path "$global:libFolder\cares.lib" -NewName "$global:libFolder\libcares.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\caresd.lib" -NewName "$global:libFolder\libcaresd.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\nghttp2.lib" -NewName "$global:libFolder\nghttp2_static.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\nghttp2d.lib" -NewName "$global:libFolder\nghttp2_staticd.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\zlibstatic.lib" -NewName "$global:libFolder\zlib_a.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\zlibstatic.lib" -NewName "$global:libFolder\zlib_ad.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:reposFolder\curl\src\tool_hugehelp.c.cvs" -NewName "$global:reposFolder\curl\src\tool_hugehelp.c" -ErrorAction 'SilentlyContinue'

    Push-Location ".\curl\winbuild"
    nmake /f Makefile.vc mode=static VC=15 WITH_DEVEL=$global:dependencyFolder WITH_SSL=static WITH_NGHTTP2=static WITH_CARES=static WITH_ZLIB=static WITH_SSH2=static
    nmake /f Makefile.vc mode=static VC=15 WITH_DEVEL=$global:dependencyFolder WITH_SSL=static WITH_NGHTTP2=static WITH_CARES=static WITH_ZLIB=static WITH_SSH2=static DEBUG=yes
    
    Push-Location "..\builds\libcurl*release*static"
    Copy-Item -Path ".\include\curl" -Destination $global:includeFolder -Recurse -Force
    Copy-Item -Path ".\lib\*.lib" -Destination $global:libFolder
    Pop-Location
    Push-Location "..\builds\libcurl*debug*static"
    Copy-Item -Path ".\lib\*.lib" -Destination $global:libFolder
    
    Rename-Item -Path "$global:libFolder\libcares.lib" -NewName "$global:libFolder\cares.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\libcaresd.lib" -NewName "$global:libFolder\caresd.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\nghttp2_static.lib" -NewName "$global:libFolder\nghttp2.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\nghttp2_staticd.lib" -NewName "$global:libFolder\nghttp2d.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\zlib_a.lib" -NewName "$global:libFolder\zlibstatic.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:libFolder\zlib_ad.lib" -NewName "$global:libFolder\zlibstaticd.lib" -ErrorAction 'SilentlyContinue'
    Rename-Item -Path "$global:reposFolder\curl\src\tool_hugehelp.c" -NewName "$global:reposFolder\curl\src\tool_hugehelp.c.cvs" -ErrorAction 'SilentlyContinue'
    Pop-Location
    Pop-Location
}

Function Build-Cares {
    If ( -not (Test-Path '.\c-ares' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/c-ares/c-ares.git
    }
    Push-Location ".\c-ares"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" -DCARES_STATIC=ON -DCARES_SHARED=OFF ..
    cmake --build ./ --config Release --target c-ares
    cmake --build ./ --config Debug --target c-ares
    Copy-Item -Path ".\lib\Release\cares.lib" -Destination $global:libFolder
    Copy-Item -Path ".\lib\Debug\cares.lib" -Destination "$global:libFolder\caresd.lib"
    Copy-Item -Path "..\include\*.h" -Destination $global:includeFolder
    Copy-Item -Path ".\*.h" -Destination $global:includeFolder
    Pop-Location
    Pop-Location
}

Function Build-LibSsh2 {
    If ( -not (Test-Path '.\libssh2' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/libssh2/libssh2.git
    }
    $Env:OPENSSL_ROOT_DIR=$global:libFolder
    Push-Location ".\libssh2"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    mkdir "$global:includeFolder\libssh2" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" ..
    cmake --build ./ --config Release --target libssh2
    cmake --build ./ --config Debug --target libssh2
    Copy-Item -Path ".\src\Release\libssh2.lib" -Destination $global:libFolder
    Copy-Item -Path ".\src\Debug\libssh2.lib" -Destination "$global:libFolder\libssh2d.lib"
    Copy-Item -Path "..\include\*.h" -Destination "$global:includeFolder\libssh2"
    Pop-Location
    Pop-Location
}

Function Build-Nghttp2 {
    If ( -not (Test-Path '.\nghttp2' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/nghttp2/nghttp2.git
    }
    $Env:OPENSSL_ROOT_DIR=$global:libFolder
    Push-Location ".\nghttp2"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    mkdir "$global:includeFolder\nghttp2" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" -DZLIB_LIBRARY="$global:libFolder" -DENABLE_STATIC_LIB=YES ..
    cmake --build ./ --config Release --target nghttp2_static
    cmake --build ./ --config Debug --target nghttp2_static
    Copy-Item -Path ".\lib\Release\nghttp2.lib" -Destination $global:libFolder
    Copy-Item -Path ".\lib\Debug\nghttp2.lib" -Destination "$global:libFolder\nghttp2d.lib"
    Copy-Item -Path ".\lib\includes\nghttp2\*.h" -Destination "$global:includeFolder\nghttp2"
    Copy-Item -Path "..\lib\includes\nghttp2\*.h" -Destination "$global:includeFolder\nghttp2"
    Pop-Location
    Pop-Location
}

Function Build-OpenSSL-Release {
    If ( -not (Test-Path '.\openssl' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/openssl/openssl.git
    }
    Push-Location ".\openssl"
    perl.exe Configure VC-WIN64A no-shared zlib no-zlib-dynamic threads --openssldir=$global:dependencyFolder --prefix=$global:dependencyFolder
    $content = Get-Content -Path 'makefile'
    $content = $content -Replace 'ZLIB1', '..\..\lib\zlibstatic.lib'
    $content | Set-Content -Path  'makefile'
    Copy-Item -Path "$global:includeFolder\zlib.h" -Destination "."
    Copy-Item -Path "$global:includeFolder\zconf.h" -Destination "."
    nmake install
    Pop-Location
}

Function Build-OpenSSL-Debug {
    If ( -not (Test-Path '.\openssl' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/openssl/openssl.git
    }
    Push-Location ".\openssl"
    perl Configure VC-WIN64A no-shared zlib no-zlib-dynamic threads -d --openssldir=$global:dependencyFolder --prefix=$global:dependencyFolder
    $content = Get-Content -Path 'makefile'
    $content = $content -Replace 'ZLIB1', '..\..\lib\zlibstatic.lib'
    $content | Set-Content -Path  'makefile'
    Copy-Item -Path "$global:includeFolder\zlib.h" -Destination "."
    Copy-Item -Path "$global:includeFolder\zconf.h" -Destination "."
    nmake install
    Rename-Item -Path "$global:libFolder\libcrypto.lib" -NewName "$global:libFolder\libcryptod.lib"
    Rename-Item -Path "$global:libFolder\libssl.lib" -NewName "$global:libFolder\libssld.lib"
    Pop-Location
}

Function Build-Bzip2 {
    If ( -not (Test-Path '.\libbzip2' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/winlibs/libbzip2.git
    }
    Push-Location ".\libbzip2"
    nmake.exe lib bzip2 -f makefile.msc
    nmake.exe lib bzip2 -f makefile_debug.msc
    Copy-Item -Path "bzlib.h" -Destination $global:includeFolder
    Copy-Item -Path "*.lib" -Destination $global:libFolder
    Rename-Item -Path "$global:libFolder\libbz2_a.lib" -NewName "$global:libFolder\libbz2.lib"
    Rename-Item -Path "$global:libFolder\libbz2_a_debug.lib" -NewName "$global:libFolder\libbz2d.lib"
    Pop-Location
}

Function Build-Zlib {
    # Get $lastExitCode or $? for true false about execution of previous command
    If ( -not (Test-Path '.\zlib' -PathType Any) ) {  
        git.exe clone --depth 1 -j4 https://github.com/madler/zlib.git
    }
    Push-Location ".\zlib"
    Remove-Item -r ".\build" -fo -ErrorAction 'SilentlyContinue'
    mkdir ".\build" -ErrorAction 'SilentlyContinue'
    Push-Location ".\build"
    cmake -G"$global:cmakeToolChain" ..
    cmake --build ./ --config Release --target zlibstatic
    cmake --build ./ --config Debug --target zlibstatic
    Copy-Item -Path "..\zlib.h" -Destination $global:includeFolder
    Copy-Item -Path "zconf.h" -Destination $global:includeFolder
    Copy-Item -Path ".\Release\*.lib" -Destination $global:libFolder
    Copy-Item -Path ".\Debug\*.lib" -Destination $global:libFolder
    Pop-Location
    Pop-Location
}

Init-Build
Push-Location '.\deps\repos'
# Build-Zlib
# Build-Bzip2
# Build-CryptoCpp
# Build-OpenSSL-Debug
# Build-OpenSSL-Release
# Build-Nghttp2
# Build-LibSsh2
# Build-Cares
# Build-Curl
# Build-CurlCpp
# Build-LibUv
# Build-uSockets
# Build-uWebSockets
Build-Boost
Pop-Location