#!/bin/zsh

set -e; set -x

build_dir="$TARGET_TEMP_DIR/Build"
install_dir="$TARGET_TEMP_DIR/Install"
[ -f "$install_dir/.make_completed" ] && exit 0

export MAKEFLAGS="-j $(sysctl -n hw.ncpu)"

cd "$build_dir"
make install

touch "$install_dir/.make_completed"
exit 0

