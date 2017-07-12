#!/bin/sh

source_dir="$PROJECT_DIR/DCMTK"
build_dir="$PROJECT_TEMP_DIR/$CONFIGURATION/$TARGET_NAME.build"
libs_dir="$build_dir/lib"
framework_path="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

cd "$source_dir"
git submodule update --init --recursive

hash="$(find "$source_dir" \( -name CMakeLists.txt -o -name '*.cmake' \) -type f -exec md5 -q {} \; | md5)-$(md5 -q "$0")-$(md5 -qs "$(env | sort)")"

shopt -s extglob; set -e; set -o xtrace

mkdir -p "$build_dir"; cd "$build_dir"

if [ ! -e "$build_dir/DCMTK.xcodeproj" -o ! -f "$build_dir/.buildhash" ] || [ "$(cat "$build_dir/.buildhash")" != "$hash" ]; then
    mv "$build_dir" "$build_dir.tmp"; rm -Rf "$build_dir.tmp"
    mkdir -p "$build_dir";

    args=( "$source_dir" -G Xcode )
    cxxfs=( -w -fvisibility=hidden -fvisibility-inlines-hidden )

    args+=(-DDCMTK_WITH_DOXYGEN=OFF)
    args+=(-DDCMTK_USE_CXX11_STL=ON)

    args+=(-DBUILD_SHARED_LIBS=OFF)

    args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
    args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
    args+=(-DCMAKE_INSTALL_PREFIX=/usr/local)

    args+=(-DCMAKE_C_FLAGS="-Wno-logical-not-parentheses")

    if [ "$CONFIGURATION" = 'Debug' ]; then
        cxxfs+=( -g )
    else
        cxxfs+=( -O2 )
    fi

    if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
        args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="$CLANG_CXX_LIBRARY")
        cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
    fi

    if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
        args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="$CLANG_CXX_LANGUAGE_STANDARD")
        cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
    fi

    if [ ${#cxxfs[@]} -ne 0 ]; then
        cxxfss="${cxxfs[@]}"
        args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
    fi

    cd "$build_dir"
    cmake "${args[@]}"

    echo "$hash" > "$build_dir/.buildhash"
fi

if [ ! -f "$libs_dir/libgdcmCommon.a" ] || [ -f "$build_dir/.incomplete" ]; then
    touch "$build_dir/.incomplete"

    cd "$build_dir"
    xcodebuild -project "$build_dir/$TARGET_NAME.xcodeproj" -target dcmdata -target dcmimgle -configuration "$CONFIGURATION"

    rm -f "$build_dir/.incomplete"
fi

cd "$libs_dir"
hash="$(find -s . -type f -name '*.a' -exec md5 -q {} \; | md5)-$(md5 -q "$0")"

if [ ! -d "$framework_path" -o ! -f "$build_dir/.frameworkhash" ] || [ "$(cat "$build_dir/.frameworkhash")" != "$hash" ]; then
    rm -Rf "$framework_path"

    mkdir -p "$framework_path/Versions/A"

    cd "$framework_path/Versions"
    ln -s A Current

    ars=$(find "$libs_dir" -name '*.a' -type f)
    libtool -static -o "$framework_path/Versions/A/$PRODUCT_NAME" $ars

    cd "$framework_path"
    ln -s "Versions/Current/$PRODUCT_NAME" "$PRODUCT_NAME"
    mkdir -p "Versions/A/Headers" # "Versions/A/Resources"
    ln -s Versions/Current/Headers Headers
    # ln -s Versions/Current/Resources Resources

    cd Headers

    find "$PROJECT_DIR/DCMTK" -path '*/include/dcmtk/*' -name '*.h*' -exec sh -c 'p="${0#*/include/dcmtk/}"; mkdir -p "$(dirname $p)"; cp -an "{}" "$p"' {} \;
    find "$build_dir" -path '*/include/dcmtk/*' -name '*.h*' -exec sh -c 'p="${0#*/include/dcmtk/}"; mkdir -p "$(dirname $p)"; cp -an "{}" "$p"' {} \;

    find . \( -name '*.hmap' -o -name '*.h.generated' -o -name '*.htm*' -o -name '*.h.in' \) -delete

    find . -type f -exec sed -i '' 's/#include "dcmtk\/\(.*\)"/#include <DCMTK\/\1>/g' {} \;

    echo "$hash" > "$build_dir/.frameworkhash"
fi

exit 0
