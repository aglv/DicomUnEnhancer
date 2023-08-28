#!/bin/zsh
[ -f ~/.zshenv ] && . ~/.zshenv

command -v git >/dev/null 2>&1 || { echo >&2 "error: Building $TARGET_NAME requires Git. Please install Git. Aborting."; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo >&2 "error: Building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }

script_path=$(readlink -f ${(%):-%x})
source_dir="$PROJECT_DIR/$PROJECT_NAME/ThirdParty/$TARGET_NAME"
source_hash="$(cd "$source_dir" && git describe --always --tags --dirty) $(md5 -q "$script_path")" # -$(md5 -qs "$env")

set -e ; set -x

build_dir="$TARGET_TEMP_DIR/Build"

mkdir -p "$build_dir"
[ -f "$build_dir/.configured_source_hash" ] && [ "$(cat "$build_dir/.configured_source_hash")" = "$source_hash" ] && exit 0

install_dir="$TARGET_TEMP_DIR/Install"

rm -Rf "$build_dir.tmp" "$install_dir.tmp"
mv "$build_dir" "$build_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$build_dir.tmp" "$install_dir.tmp"
mkdir -p "$build_dir"

args=( "$source_dir" )
fs=( -w -Wno-unqualified-std-cast-call ) # -Wno-dev
cfs=()
cxxfs=()

# add fs to cfs and cxxfs
if [ ${#fs[@]} -ne 0 ]; then
    cfs+=( ${fs[@]} )
    cxxfs+=( ${fs[@]} )
fi

ds=()
# make string vars now, don't convert in array creation or it'll split into multiple strings
cfss="${cfs[@]}"
cxxfss="${cxxfs[@]}"

#ds+=( BATCH_VERSION:BOOL=OFF ) # Build dcm2niibatch for multiple conversions
#ds+=( BUILD_DCM2NIIXFSLIB:BOOL=OFF ) # Build libdcm2niixfs.a
#ds+=( BUILD_DOCS:BOOL=OFF ) # Build documentation (manpages)
#ds+=( CMAKE_ADDR2LINE:FILEPATH=CMAKE_ADDR2LINE-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_AR:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar ) # Path to a program.
#ds+=( CMAKE_BUILD_TYPE:STRING=Release ) # Choose the type of build.
ds+=( CMAKE_COLOR_MAKEFILE:BOOL=OFF ) # Enable/Disable color output during build.
#ds+=( CMAKE_CXX_COMPILER:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ ) # CXX compiler
ds+=( CMAKE_CXX_FLAGS:STRING="$cxxfss" ) # Flags used by the CXX compiler during all build types.
#ds+=( CMAKE_CXX_FLAGS_DEBUG:STRING=-g ) # Flags used by the CXX compiler during DEBUG builds.
#ds+=( CMAKE_CXX_FLAGS_MINSIZEREL:STRING=-Os -DNDEBUG ) # Flags used by the CXX compiler during MINSIZEREL builds.
#ds+=( CMAKE_CXX_FLAGS_RELEASE:STRING=-O3 -DNDEBUG ) # Flags used by the CXX compiler during RELEASE builds.
#ds+=( CMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING=-O2 -g -DNDEBUG ) # Flags used by the CXX compiler during RELWITHDEBINFO builds.
#ds+=( CMAKE_C_COMPILER:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc ) # C compiler
ds+=( CMAKE_C_FLAGS:STRING="$cfss" ) # Flags used by the C compiler during all build types.
#ds+=( CMAKE_C_FLAGS_DEBUG:STRING=-g ) # Flags used by the C compiler during DEBUG builds.
#ds+=( CMAKE_C_FLAGS_MINSIZEREL:STRING=-Os -DNDEBUG ) # Flags used by the C compiler during MINSIZEREL builds.
#ds+=( CMAKE_C_FLAGS_RELEASE:STRING=-O3 -DNDEBUG ) # Flags used by the C compiler during RELEASE builds.
#ds+=( CMAKE_C_FLAGS_RELWITHDEBINFO:STRING=-O2 -g -DNDEBUG ) # Flags used by the C compiler during RELWITHDEBINFO builds.
#ds+=( CMAKE_DLLTOOL:FILEPATH=CMAKE_DLLTOOL-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_EXE_LINKER_FLAGS:STRING= ) # Flags used by the linker during all build types.
#ds+=( CMAKE_EXE_LINKER_FLAGS_DEBUG:STRING= ) # Flags used by the linker during DEBUG builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_MINSIZEREL:STRING= ) # Flags used by the linker during MINSIZEREL builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_RELEASE:STRING= ) # Flags used by the linker during RELEASE builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO:STRING= ) # Flags used by the linker during RELWITHDEBINFO builds.
#ds+=( CMAKE_EXPORT_COMPILE_COMMANDS:BOOL= ) # Enable/Disable output of compile commands during generation.
#ds+=( CMAKE_INSTALL_NAME_TOOL:FILEPATH=/usr/bin/install_name_tool ) # Path to a program.
ds+=( CMAKE_INSTALL_PREFIX:PATH="$install_dir" ) # Install path prefix, prepended onto install directories.
#ds+=( CMAKE_LINKER:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld ) # Path to a program.
#ds+=( CMAKE_MAKE_PROGRAM:FILEPATH=/usr/bin/make ) # Path to a program.
#ds+=( CMAKE_MODULE_LINKER_FLAGS:STRING= ) # Flags used by the linker during the creation of modules during all build types.
#ds+=( CMAKE_MODULE_LINKER_FLAGS_DEBUG:STRING= ) # Flags used by the linker during the creation of modules during DEBUG builds.
#ds+=( CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL:STRING= ) # Flags used by the linker during the creation of modules during MINSIZEREL builds.
#ds+=( CMAKE_MODULE_LINKER_FLAGS_RELEASE:STRING= ) # Flags used by the linker during the creation of modules during RELEASE builds.
#ds+=( CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO:STRING= ) # Flags used by the linker during the creation of modules during RELWITHDEBINFO builds.
#ds+=( CMAKE_NM:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm ) # Path to a program.
#ds+=( CMAKE_OBJCOPY:FILEPATH=CMAKE_OBJCOPY-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_OBJDUMP:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/objdump ) # Path to a program.
#ds+=( CMAKE_OSX_ARCHITECTURES:STRING= ) # Build architectures for OSX # seems to be ignored
ds+=( CMAKE_OSX_DEPLOYMENT_TARGET:STRING="$MACOSX_DEPLOYMENT_TARGET" ) # Minimum OS X version to target for deployment (at runtime); newer APIs weak linked. Set to empty string for default value.
#ds+=( CMAKE_OSX_SYSROOT:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk ) # The product will be built against the headers and libraries located inside the indicated SDK.
#ds+=( CMAKE_RANLIB:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib ) # Path to a program.
#ds+=( CMAKE_READELF:FILEPATH=CMAKE_READELF-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_SHARED_LINKER_FLAGS:STRING= ) # Flags used by the linker during the creation of shared libraries during all build types.
#ds+=( CMAKE_SHARED_LINKER_FLAGS_DEBUG:STRING= ) # Flags used by the linker during the creation of shared libraries during DEBUG builds.
#ds+=( CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL:STRING= ) # Flags used by the linker during the creation of shared libraries during MINSIZEREL builds.
#ds+=( CMAKE_SHARED_LINKER_FLAGS_RELEASE:STRING= ) # Flags used by the linker during the creation of shared libraries during RELEASE builds.
#ds+=( CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO:STRING= ) # Flags used by the linker during the creation of shared libraries during RELWITHDEBINFO builds.
#ds+=( CMAKE_SKIP_INSTALL_RPATH:BOOL=NO ) # If set, runtime paths are not added when installing shared libraries, but are added when building.
#ds+=( CMAKE_SKIP_RPATH:BOOL=NO ) # If set, runtime paths are not added when using shared libraries.
#ds+=( CMAKE_STATIC_LINKER_FLAGS:STRING= ) # Flags used by the linker during the creation of static libraries during all build types.
#ds+=( CMAKE_STATIC_LINKER_FLAGS_DEBUG:STRING= ) # Flags used by the linker during the creation of static libraries during DEBUG builds.
#ds+=( CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL:STRING= ) # Flags used by the linker during the creation of static libraries during MINSIZEREL builds.
#ds+=( CMAKE_STATIC_LINKER_FLAGS_RELEASE:STRING= ) # Flags used by the linker during the creation of static libraries during RELEASE builds.
#ds+=( CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO:STRING= ) # Flags used by the linker during the creation of static libraries during RELWITHDEBINFO builds.
#ds+=( CMAKE_STRIP:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip ) # Path to a program.
#ds+=( CMAKE_TAPI:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi ) # Path to a program.
#ds+=( CMAKE_VERBOSE_MAKEFILE:BOOL=FALSE ) # If this value is on, makefiles will be generated without the .SILENT directive, and all commands will be echoed to the console during the make.  This is useful for debugging only. With Visual Studio IDE projects all commands are done without /nologo.
#ds+=( GIT_EXECUTABLE:FILEPATH=/usr/bin/git ) # Git command line client
#ds+=( INSTALL_DEPENDENCIES:BOOL=OFF ) # Optionally install built dependent libraries (OpenJPEG and yaml-cpp) for future use.
#ds+=( USE_JASPER:BOOL=OFF ) # Build with JPEG2000 support using Jasper
#ds+=( USE_JNIFTI:BOOL=ON ) # Build with JNIFTI support
ds+=( USE_JPEGLS:BOOL=ON ) # default is OFF # Build with JPEG-LS support using CharLS
ds+=( USE_OPENJPEG:STRING=ON ) # default is OFF # Build with JPEG2000 support using OpenJPEG.
#ds+=( USE_STATIC_RUNTIME:BOOL=ON ) # Use static runtime
#ds+=( USE_TURBOJPEG:BOOL=OFF ) # Use TurboJPEG to decode classic JPEG
#ds+=( ZLIB_IMPLEMENTATION:STRING=Miniz ) # Choose zlib implementation.

for d in "${ds[@]}"; do
    args+=( -D "$d" )
done

cd "$build_dir"
cmake "${args[@]}"

echo "$source_hash" > "$build_dir/.configured_source_hash"

exit 0

