#!/Bin/bash

SRC_FOLDER="$1"
VOLUME_NAME="$1"
VOLUME_ICON_FILE="DevEnvIcon-Black.icns"
BACKGROUND_FILE="DevEnvDmgBg.png"
BACKGROUND_FILE_NAME="VolumeBackground.png"
DS_STORE_FILE="DevEnvCtrl-DS_Store"
APPLESCRIPT="DevEnvCtrl-Make-Dmg.scpt"
DMG_NAME="$1.dmg"
DMG_TEMP_NAME="$1-temp.dmg"
DMG_SIZE="16"

echo "Creating disk image..."
hdiutil create -srcfolder "$SRC_FOLDER" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "${DMG_TEMP_NAME}"

echo "Mounting disk image..."
MOUNT_DIR="/Volumes/${VOLUME_NAME}"
echo "Mount directory:\t$MOUNT_DIR"
DEV_NAME=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP_NAME}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
echo "Device name:\t$DEV_NAME"

echo "Copying background file..."
cp "$BACKGROUND_FILE" "$MOUNT_DIR/$BACKGROUND_FILE_NAME"

echo "making link to Applications dir"
ln -s /Applications "$MOUNT_DIR/Applications"

echo "Copying volume icon file '$VOLUME_ICON_FILE'..."
cp "$VOLUME_ICON_FILE" "$MOUNT_DIR/.VolumeIcon.icns"

osascript "${APPLESCRIPT}" "${VOLUME_NAME}"

echo "Fixing permissions..."
chmod -Rf go-w "${MOUNT_DIR}" &> /dev/null

echo "Blessing started"
bless --folder "${MOUNT_DIR}" --openfolder "${MOUNT_DIR}"

echo "Setting file attributes ..."
SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns"
SetFile -a V "$MOUNT_DIR/$BACKGROUND_FILE_NAME"
SetFile -a C "$MOUNT_DIR"

echo "Unmounting disk image..."
hdiutil detach "${DEV_NAME}"

echo "Compressing disk image..."
hdiutil convert "${DMG_TEMP_NAME}" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}"
rm -f "${DMG_TEMP_NAME}"