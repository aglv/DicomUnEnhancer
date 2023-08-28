#!/bin/zsh

set -e; set -x

source_dir="$PROJECT_DIR/$PROJECT_NAME/ThirdParty/$TARGET_NAME"
install_dir="$TARGET_TEMP_DIR/Install"

versioned_filename="dcm2niix_${NATIVE_ARCH}_$(cd "$source_dir" && git describe --tags --dirty)"

rsync -avz "$install_dir/bin/dcm2niix" "$TARGET_BUILD_DIR/$versioned_filename"

rm "$TARGET_BUILD_DIR/dcm2niix"
ln -s "$versioned_filename" "$TARGET_BUILD_DIR/dcm2niix"

