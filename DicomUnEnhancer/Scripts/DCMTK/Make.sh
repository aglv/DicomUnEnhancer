#!/bin/zsh

set -e; set -x

build_dir="$TARGET_TEMP_DIR/Build"
install_dir="$TARGET_TEMP_DIR/Install"
[ -f "$install_dir/.make_completed" ] && exit 0

export MAKEFLAGS="-j $(sysctl -n hw.ncpu)"

cd "$build_dir"
make install

# wrap the libs into one
mkdir -p "$install_dir/wlib"
cd "$install_dir/lib"
ars=$( find . -name '*.a' -type f )
libtool -static -o "$install_dir/wlib/lib$PRODUCT_NAME.a" $ars

touch "$install_dir/.make_completed"
exit 0

