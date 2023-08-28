#!/bin/zsh

set -e; set -x

for file in DicomUnEnhancer/Binaries/dcm2niix-*; do
    rsync -avz "$file" "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME/Contents/Resources/$(basename "$file" | cut -f1,2 -d'-' )"
done

exit 0
