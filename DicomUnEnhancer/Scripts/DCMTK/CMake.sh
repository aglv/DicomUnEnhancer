#!/bin/zsh
[ -f ~/.zshenv ] && . ~/.zshenv

path=$(readlink -f ${BASH_SOURCE[0]})

source_dir="$PROJECT_DIR/$PROJECT_NAME/ThirdParty/$TARGET_NAME"
source_hash="$(cd "$source_dir" && git describe --always --tags --dirty) $(md5 -q "$path")" # -$(md5 -qs "$env")

set -e ; set -x

build_dir="$TARGET_TEMP_DIR/Build"

mkdir -p "$build_dir"
[ -f "$build_dir/.configured_source_hash" ] && [ "$(cat "$build_dir/.configured_source_hash")" = "$source_hash" ] && exit 0

#set +x ; echo "$env" > "$build_dir/.cmakeenv.now" ; set -x
#[ -f "$build_dir/.cmakeenv" ] && set +e && diff "$build_dir/.cmakeenv" "$build_dir/.cmakeenv.now" && set -e

command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }

install_dir="$TARGET_TEMP_DIR/Install"

rm -Rf "$build_dir.tmp" "$install_dir.tmp"
mv "$build_dir" "$build_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$build_dir.tmp" "$install_dir.tmp"
mkdir -p "$build_dir"

args=( "$source_dir" )
fs=( -w -Wno-dev )
cfs=( -Wno-logical-not-parentheses )
cxxfs=()

visibility="hidden" # hidden is the default
[ "$visibility" = 'hidden' ] || cfs+=( -fvisibility="$visibility" ) # so only specify if not hidden
[ "$visibility" = 'hidden' ] || cxxfs+=( -fvisibility="$visibility" ) # so only specify if not hidden
[ "$visibility" = 'hidden' ] && cxxfs+=( -fvisibility-inlines-hidden )

if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
    cxxfs+=( -stdlib="$CLANG_CXX_LIBRARY" )
fi

if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
    cxxfs+=( -std="$CLANG_CXX_LANGUAGE_STANDARD" )
else
    cxxfs+=( -std="c++14" )
fi

# add fs to cfs and cxxfs
if [ ${#fs[@]} -ne 0 ]; then
    cfs+=( ${fs[@]} )
    cxxfs+=( ${fs[@]} )
fi

ds=()
# make string vars now, don't convert in array creation or it'll split into multiple strings
cfss="${cfs[@]}"
cxxfss="${cxxfs[@]}"

ds+=( BUILD_APPS:BOOL=OFF ) # default is ON # Build command line applications and test programs.
#ds+=( BUILD_SHARED_LIBS:BOOL=OFF ) # Build with shared libraries.
#ds+=( BUILD_SINGLE_SHARED_LIBRARY:BOOL=ON ) # default is OFF # Build a single DCMTK library.
#ds+=( CMAKE_ADDR2LINE:FILEPATH=CMAKE_ADDR2LINE-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_AR:FILEPATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar ) # Path to a program.

#ds+=( CMAKE_BUILD_TYPE:STRING=Release ) # Choose the type of build.
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
if [ "$CONFIGURATION" == 'Release' ]; then
    ds+=( CMAKE_BUILD_TYPE:STRING=RelWithDebInfo ) # Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel ...
    ds+=( CMAKE_C_FLAGS_RELWITHDEBINFO:STRING='-O3 -g -DNDEBUG' ) # default is '-O2 -g -DNDEBUG' # Flags used by the C compiler during RELWITHDEBINFO builds.
    ds+=( CMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING='-O3 -g -DNDEBUG' ) # default is '-O2 -g -DNDEBUG' # Flags used by the CXX compiler during RELWITHDEBINFO builds.
else
    ds+=( CMAKE_BUILD_TYPE:STRING=RelWithDebInfo ) # Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel ...
fi

ds+=( CMAKE_COLOR_MAKEFILE:BOOL=OFF ) # default is ON # Enable/Disable color output during build.
#ds+=( CMAKE_DEBUG_POSTFIX:STRING= ) # Library postfix for debug builds. Usually left blank.
#ds+=( CMAKE_DLLTOOL:FILEPATH=CMAKE_DLLTOOL-NOTFOUND ) # Path to a program.
#ds+=( CMAKE_EXE_LINKER_FLAGS:STRING= ) # Flags used by the linker during all build types.
#ds+=( CMAKE_EXE_LINKER_FLAGS_DEBUG:STRING= ) # Flags used by the linker during DEBUG builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_MINSIZEREL:STRING= ) # Flags used by the linker during MINSIZEREL builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_RELEASE:STRING= ) # Flags used by the linker during RELEASE builds.
#ds+=( CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO:STRING= ) # Flags used by the linker during RELWITHDEBINFO builds.
#ds+=( CMAKE_EXPORT_COMPILE_COMMANDS:BOOL= ) # Enable/Disable output of compile commands during generation.
#ds+=( CMAKE_INSTALL_BINDIR:PATH=bin ) # User executables (bin)
#ds+=( CMAKE_INSTALL_DATADIR:PATH= ) # Read-only architecture-independent data (DATAROOTDIR)
#ds+=( CMAKE_INSTALL_DATAROOTDIR:PATH=share ) # Read-only architecture-independent data root (share)
#ds+=( CMAKE_INSTALL_DOCDIR:PATH= ) # Documentation root (DATAROOTDIR/doc/PROJECT_NAME)
#ds+=( CMAKE_INSTALL_INCLUDEDIR:PATH=include ) # C header files (include)
#ds+=( CMAKE_INSTALL_INFODIR:PATH= ) # Info documentation (DATAROOTDIR/info)
#ds+=( CMAKE_INSTALL_LIBDIR:PATH=lib ) # Object code libraries (lib)
#ds+=( CMAKE_INSTALL_LIBEXECDIR:PATH=libexec ) # Program executables (libexec)
#ds+=( CMAKE_INSTALL_LOCALEDIR:PATH= ) # Locale-dependent data (DATAROOTDIR/locale)
#ds+=( CMAKE_INSTALL_LOCALSTATEDIR:PATH=var ) # Modifiable single-machine data (var)
#ds+=( CMAKE_INSTALL_MANDIR:PATH= ) # Man documentation (DATAROOTDIR/man)
#ds+=( CMAKE_INSTALL_NAME_TOOL:FILEPATH=/usr/bin/install_name_tool ) # Path to a program.
#ds+=( CMAKE_INSTALL_OLDINCLUDEDIR:PATH=/usr/include ) # C header files for non-gcc (/usr/include)
ds+=( CMAKE_INSTALL_PREFIX:PATH="$install_dir" ) # Install path prefix, prepended onto install directories.
#ds+=( CMAKE_INSTALL_RUNSTATEDIR:PATH= ) # Run-time variable data (LOCALSTATEDIR/run)
#ds+=( CMAKE_INSTALL_SBINDIR:PATH=sbin ) # System admin executables (sbin)
#ds+=( CMAKE_INSTALL_SHAREDSTATEDIR:PATH=com ) # Modifiable architecture-independent data (com)
#ds+=( CMAKE_INSTALL_SYSCONFDIR:PATH=etc ) # Read-only single-machine data (etc)
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
ds+=( CMAKE_OSX_ARCHITECTURES:STRING="${ARCHS// /;}" ) # Build architectures for OSX
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
#ds+=( CMAKE_VERBOSE_MAKEFILE:BOOL=FALSE ) # If this value is on, makefiles will be generated without the .SILENT directive, and all commands will be echoed to the console during the make.  This is useful for debugging only. With Visual Studio IDE projects all commands are done without /nologo.
#ds+=( DCMTK_DEFAULT_DICT:STRING=external ) # Denotes whether DCMTK will use built-in (compiled-in), external (file), or no default dictionary on startup
#ds+=( DCMTK_ENABLE_CHARSET_CONVERSION:STRING=libiconv ) # Select character set conversion implementation.
ds+=( DCMTK_ENABLE_CXX11:STRING=ON ) # Enable use of native C++11 features (eg. move semantics).
#ds+=( DCMTK_ENABLE_LFS:STRING=lfs ) # whether to use lfs/lfs64 or not
#ds+=( DCMTK_ENABLE_MANPAGES:BOOL=ON ) # Enable building/installing of manpages.
ds+=( DCMTK_ENABLE_PRIVATE_TAGS:BOOL=ON ) # Configure DCMTK with support for DICOM private tags coming with DCMTK.
ds+=( DCMTK_ENABLE_STL:BOOL=ON ) # Enable use of native STL classes and algorithms instead of DCMTK's own implementations.
#ds+=( DCMTK_ENABLE_STL_ALGORITHM:STRING=INFERRED ) # Enable use of STL algorithm.
#ds+=( DCMTK_ENABLE_STL_LIMITS:STRING=INFERRED ) # Enable use of STL limit.
#ds+=( DCMTK_ENABLE_STL_LIST:STRING=INFERRED ) # Enable use of STL list.
#ds+=( DCMTK_ENABLE_STL_MAP:STRING=INFERRED ) # Enable use of STL map.
#ds+=( DCMTK_ENABLE_STL_MEMORY:STRING=INFERRED ) # Enable use of STL memory.
#ds+=( DCMTK_ENABLE_STL_STACK:STRING=INFERRED ) # Enable use of STL stack.
#ds+=( DCMTK_ENABLE_STL_STRING:STRING=INFERRED ) # Enable use of STL string.
#ds+=( DCMTK_ENABLE_STL_SYSTEM_ERROR:STRING=INFERRED ) # Enable use of STL system_error.
#ds+=( DCMTK_ENABLE_STL_TUPLE:STRING=INFERRED ) # Enable use of STL tuple.
#ds+=( DCMTK_ENABLE_STL_TYPE_TRAITS:STRING=INFERRED ) # Enable use of STL type traits.
#ds+=( DCMTK_ENABLE_STL_VECTOR:STRING=INFERRED ) # Enable use of STL vector.
#ds+=( DCMTK_FORCE_FPIC_ON_UNIX:BOOL=OFF ) # Add -fPIC compiler flag on unix 64 bit machines to allow linking from dynamic libraries even if DCMTK is built statically
#ds+=( DCMTK_GENERATE_DOXYGEN_TAGFILE:BOOL=OFF ) # Generate a tag file with DOXYGEN.
#ds+=( DCMTK_LINK_STATIC:BOOL=OFF ) # Statically link all libraries and tools with the runtime and third party libraries.
ds+=( DCMTK_MODULES:STRING="ofstd;oflog;dcmdata;dcmimgle" ) # List of modules that should be built. # removed: config;dcmimage;dcmjpeg;dcmjpls;dcmtls;dcmnet;dcmsr;dcmsign;dcmwlm;dcmqrdb;dcmpstat;dcmrt;dcmiod;dcmfg;dcmseg;dcmtract;dcmpmap;dcmect
#ds+=( DCMTK_PORTABLE_LINUX_BINARIES:BOOL=OFF ) # Create ELF binaries while statically linking all third party libraries and libstdc++.
ds+=( DCMTK_PRESERVE_IMAGETYPE:BOOL=ON ) # default is OFF # Don't set ImageType to DERIVED when re-encoding.
#ds+=( DCMTK_TLS_LIBRARY_POSTFIX:STRING= ) # Postfix for libraries that change their ABI when using OpenSSL.
#ds+=( DCMTK_USE_DCMDICTPATH:BOOL=ON ) # Enable reading dictionary that is defined through DCMDICTPATH environment variable.
#ds+=( DCMTK_USE_FIND_PACKAGE:BOOL=TRUE ) # Control whether libraries are searched via CMake's find_package() mechanism or a Windows specific fallback
#ds+=( DCMTK_WIDE_CHAR_FILE_IO_FUNCTIONS:BOOL=OFF ) # Build with wide char file I/O functions.
#ds+=( DCMTK_WIDE_CHAR_MAIN_FUNCTION:BOOL=OFF ) # Build command line tools with wide char main function.
#ds+=( DCMTK_WITH_DOXYGEN:BOOL=OFF ) #

#openjpeg_install_dir="$CONFIGURATION_TEMP_DIR/OpenJPEG.build/Install"

#ds+=( DCMTK_WITH_ICONV:BOOL=ON ) # Configure DCMTK with support for ICONV.
#ds+=( DCMTK_WITH_ICU:BOOL=OFF ) #
#ds+=( DCMTK_WITH_OPENJPEG:BOOL=ON ) # Configure DCMTK with support for OPENJPEG. # DCMTK_WITH_OPENJPEG=ON OPENJPEG_LIBRARY="$openjpeg_install_dir/lib" OPENJPEG_INCLUDE_DIR="$openjpeg_install_dir/include"
ds+=( DCMTK_WITH_OPENSSL:BOOL=OFF ) # default is ON # Configure DCMTK with support for OPENSSL. # # DCMTK_WITH_OPENSSL=ON WITH_OPENSSLINC="$CONFIGURATION_TEMP_DIR/OpenSSL.build/Install" OPENSSL_ROOT_DIR="$CONFIGURATION_TEMP_DIR/OpenSSL.build/Install"
ds+=( DCMTK_WITH_PNG:BOOL=OFF ) # default is ON # Configure DCMTK with support for PNG.
ds+=( DCMTK_WITH_SNDFILE:BOOL=OFF ) # default is ON # Configure DCMTK with support for SNDFILE.
#ds+=( DCMTK_WITH_STDLIBC_ICONV:BOOL=OFF ) #
#ds+=( DCMTK_WITH_THREADS:BOOL=ON ) # Configure DCMTK with support for multi-threading.
ds+=( DCMTK_WITH_TIFF:BOOL=OFF ) # default is ON # Configure DCMTK with support for TIFF.
#ds+=( DCMTK_WITH_WRAP:BOOL=OFF ) #
#ds+=( DCMTK_WITH_XML:BOOL=ON ) # Configure DCMTK with support for XML.
#ds+=( DCMTK_WITH_ZLIB:BOOL=ON ) # Configure DCMTK with support for ZLIB.

#ds+=( DOXYGEN_DOT_EXECUTABLE:FILEPATH=DOXYGEN_DOT_EXECUTABLE-NOTFOUND ) # Dot tool for use with Doxygen
#ds+=( DOXYGEN_EXECUTABLE:FILEPATH=DOXYGEN_EXECUTABLE-NOTFOUND ) # Doxygen documentation generation tool (https://www.doxygen.nl)
#ds+=( ICU_DATA_LIBRARY_DEBUG:FILEPATH=ICU_DATA_LIBRARY_DEBUG-NOTFOUND ) # ICU data library (debug)
#ds+=( ICU_DATA_LIBRARY_RELEASE:FILEPATH=ICU_DATA_LIBRARY_RELEASE-NOTFOUND ) # ICU data library (release)
#ds+=( ICU_DERB_EXECUTABLE:FILEPATH=ICU_DERB_EXECUTABLE-NOTFOUND ) # ICU derb executable
#ds+=( ICU_GENBRK_EXECUTABLE:FILEPATH=ICU_GENBRK_EXECUTABLE-NOTFOUND ) # ICU genbrk executable
#ds+=( ICU_GENCCODE_EXECUTABLE:FILEPATH=ICU_GENCCODE_EXECUTABLE-NOTFOUND ) # ICU genccode executable
#ds+=( ICU_GENCFU_EXECUTABLE:FILEPATH=ICU_GENCFU_EXECUTABLE-NOTFOUND ) # ICU gencfu executable
#ds+=( ICU_GENCMN_EXECUTABLE:FILEPATH=ICU_GENCMN_EXECUTABLE-NOTFOUND ) # ICU gencmn executable
#ds+=( ICU_GENCNVAL_EXECUTABLE:FILEPATH=ICU_GENCNVAL_EXECUTABLE-NOTFOUND ) # ICU gencnval executable
#ds+=( ICU_GENDICT_EXECUTABLE:FILEPATH=ICU_GENDICT_EXECUTABLE-NOTFOUND ) # ICU gendict executable
#ds+=( ICU_GENNORM2_EXECUTABLE:FILEPATH=ICU_GENNORM2_EXECUTABLE-NOTFOUND ) # ICU gennorm2 executable
#ds+=( ICU_GENRB_EXECUTABLE:FILEPATH=ICU_GENRB_EXECUTABLE-NOTFOUND ) # ICU genrb executable
#ds+=( ICU_GENSPREP_EXECUTABLE:FILEPATH=ICU_GENSPREP_EXECUTABLE-NOTFOUND ) # ICU gensprep executable
#ds+=( ICU_ICU-CONFIG_EXECUTABLE:FILEPATH=ICU_ICU-CONFIG_EXECUTABLE-NOTFOUND ) # ICU icu-config executable
#ds+=( ICU_ICUINFO_EXECUTABLE:FILEPATH=ICU_ICUINFO_EXECUTABLE-NOTFOUND ) # ICU icuinfo executable
#ds+=( ICU_ICUPKG_EXECUTABLE:FILEPATH=ICU_ICUPKG_EXECUTABLE-NOTFOUND ) # ICU icupkg executable
#ds+=( ICU_INCLUDE_DIR:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/include ) # ICU include directory
#ds+=( ICU_MAKECONV_EXECUTABLE:FILEPATH=ICU_MAKECONV_EXECUTABLE-NOTFOUND ) # ICU makeconv executable
#ds+=( ICU_MAKEFILE_INC:FILEPATH=ICU_MAKEFILE_INC-NOTFOUND ) # ICU Makefile.inc data file
#ds+=( ICU_PKGDATA_EXECUTABLE:FILEPATH=ICU_PKGDATA_EXECUTABLE-NOTFOUND ) # ICU pkgdata executable
#ds+=( ICU_PKGDATA_INC:FILEPATH=ICU_PKGDATA_INC-NOTFOUND ) # ICU pkgdata.inc data file
#ds+=( ICU_UCONV_EXECUTABLE:FILEPATH=ICU_UCONV_EXECUTABLE-NOTFOUND ) # ICU uconv executable
#ds+=( ICU_UC_LIBRARY_DEBUG:FILEPATH=ICU_UC_LIBRARY_DEBUG-NOTFOUND ) # ICU uc library (debug)
#ds+=( ICU_UC_LIBRARY_RELEASE:FILEPATH=ICU_UC_LIBRARY_RELEASE-NOTFOUND ) # ICU uc library (release)
#ds+=( Iconv_INCLUDE_DIR:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/include ) # iconv include directory
#ds+=( Iconv_LIBRARY:FILEPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/lib/libiconv.tbd ) # iconv library (if not in the C library)
#ds+=( JPEG_INCLUDE_DIR:PATH=/Library/Frameworks/Mono.framework/Headers ) # Path to a file.
#ds+=( JPEG_LIBRARY_DEBUG:FILEPATH=JPEG_LIBRARY_DEBUG-NOTFOUND ) # Path to a library.
#ds+=( JPEG_LIBRARY_RELEASE:FILEPATH=/opt/homebrew/lib/libjpeg.dylib ) # Path to a library.
#ds+=( LIBCHARSET_INCLUDE_DIR:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/include ) # Path to a file.
#ds+=( LIBCHARSET_LIBRARY:FILEPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/lib/libcharset.tbd ) # Path to a library.
#ds+=( LIBXML2_INCLUDE_DIR:PATH=/Library/Developer/CommandLineTools/SDKs/MacOSX12.sdk/usr/include/libxml2 ) # Path to a file.
#ds+=( LIBXML2_LIBRARY:FILEPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/lib/libxml2.tbd ) # Path to a library.
#ds+=( LIBXML2_XMLLINT_EXECUTABLE:FILEPATH=/usr/bin/xmllint ) # Path to a program.
#ds+=( OPENSSL_CRYPTO_LIBRARY:FILEPATH=/opt/homebrew/Cellar/openssl@3/3.1.1_1/lib/libcrypto.dylib ) # Path to a library.
#ds+=( OPENSSL_INCLUDE_DIR:PATH=/opt/homebrew/Cellar/openssl@3/3.1.1_1/include ) # Path to a file.
#ds+=( OPENSSL_SSL_LIBRARY:FILEPATH=/opt/homebrew/Cellar/openssl@3/3.1.1_1/lib/libssl.dylib ) # Path to a library.
#ds+=( OpenJPEG_DIR:PATH=/opt/homebrew/lib/openjpeg-2.5 ) # The directory containing a CMake configuration file for OpenJPEG.
#ds+=( PKG_CONFIG_ARGN:STRING= ) # Arguments to supply to pkg-config
#ds+=( PKG_CONFIG_EXECUTABLE:FILEPATH=/opt/homebrew/bin/pkg-config ) # pkg-config executable
#ds+=( PNG_LIBRARY_DEBUG:FILEPATH=PNG_LIBRARY_DEBUG-NOTFOUND ) # Path to a library.
#ds+=( PNG_LIBRARY_RELEASE:FILEPATH=/opt/homebrew/lib/libpng.dylib ) # Path to a library.
#ds+=( PNG_PNG_INCLUDE_DIR:PATH=/Library/Frameworks/Mono.framework/Headers ) # Path to a file.
#ds+=( SNDFILE_INCLUDE_DIR:PATH=/opt/homebrew/include ) # Path to a file.
#ds+=( SNDFILE_LIBRARY:FILEPATH=/opt/homebrew/lib/libsndfile.dylib ) # Path to a library.
#ds+=( TIFF_INCLUDE_DIR:PATH=/Library/Frameworks/Mono.framework/Headers ) # Path to a file.
#ds+=( TIFF_LIBRARY_DEBUG:FILEPATH=TIFF_LIBRARY_DEBUG-NOTFOUND ) # Path to a library.
#ds+=( TIFF_LIBRARY_RELEASE:FILEPATH=/opt/homebrew/lib/libtiff.dylib ) # Path to a library.
#ds+=( WRAP_INCLUDE_DIR:PATH=WRAP_INCLUDE_DIR-NOTFOUND ) # Path to a file.
#ds+=( WRAP_LIBRARY:FILEPATH=WRAP_LIBRARY-NOTFOUND ) # Path to a library.
#ds+=( ZLIB_INCLUDE_DIR:PATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/include ) # Path to a file.
#ds+=( ZLIB_LIBRARY_DEBUG:FILEPATH=ZLIB_LIBRARY_DEBUG-NOTFOUND ) # Path to a library.
#ds+=( ZLIB_LIBRARY_RELEASE:FILEPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/lib/libz.tbd ) # Path to a library.
#ds+=( pkgcfg_lib_PC_LIBXML_xml2:FILEPATH=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk/usr/lib/libxml2.tbd ) # Path to a library.
#ds+=( pkgcfg_lib__OPENSSL_crypto:FILEPATH=/opt/homebrew/Cellar/openssl@3/3.1.1_1/lib/libcrypto.dylib ) # Path to a library.
#ds+=( pkgcfg_lib__OPENSSL_ssl:FILEPATH=/opt/homebrew/Cellar/openssl@3/3.1.1_1/lib/libssl.dylib ) # Path to a library.

#args+=(-DCMAKE_CXX_VISIBILITY_PRESET:STRING=hidden)
#args+=(-DCMAKE_XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN:BOOL=ON)
#args+=(-DCMAKE_VISIBILITY_INLINES_HIDDEN:BOOL=ON)
#args+=(-DCMAKE_XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN:BOOL=ON)

for d in "${ds[@]}"; do
    args+=( -D "$d" )
done

#args+=(--trace --debug-output --debug-trycompile)

cd "$build_dir"
cmake "${args[@]}"

echo "$source_hash" > "$build_dir/.configured_source_hash"

exit 0

