#!/bin/bash
#
# Script for making boot-recovery.img from existing tissot out files (patches-out skip_initramfs)
#

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RAMDISK_FILE=ramdisk-recovery.img
OUT_DIR=../../../../out/target/product/tissot
# boot-recovery.img stuff
IMAGE_SOURCE=$OUT_DIR/obj/KERNEL_OBJ/arch/arm64/boot/Image
IMAGE_TARGET=$OUT_DIR/ImageSkipInitRamFs
IMAGE_GZ_TARGET=$OUT_DIR/ImageSkipInitRamFs.gz
DTB_SOURCE=$OUT_DIR/obj/KERNEL_OBJ/arch/arm64/boot/dts/qcom/msm8953-qrd-sku3.dtb
IMAGE_GZ_DTB_TARGET=$OUT_DIR/ImageSkipInitRamFs.gz-dtb
RAMDISK_SOURCE=$OUT_DIR/$RAMDISK_FILE
BOOT_RECOVERY_TARGET=$OUT_DIR/boot-recovery.img
# recovery-installer stuff
RECOVERY_INSTALLER_TEMPLATE=recovery_installer_template.zip
RECOVERY_INSTALLER_OUT=recovery-installer.zip

echo "[#] Making boot-recovery.img..."

# Copy uncompressed kernel image
cp -f "$IMAGE_SOURCE" "$IMAGE_TARGET"

# Patch kernel image for skip_initramfs
perl -pi -e 's/skip_initramfs/keep_initramfs/g' "$IMAGE_TARGET"

# Pack image.gz
cat "$IMAGE_TARGET" | gzip -n -f -9 > "$IMAGE_GZ_TARGET"
rm "$IMAGE_TARGET"

# Append DTB
cat "$IMAGE_GZ_TARGET" "$DTB_SOURCE" > "$IMAGE_GZ_DTB_TARGET"
rm "$IMAGE_GZ_TARGET"

# Pack boot-recovery.img
#--base 0x80000000 --pagesize 2048 --os_version 8.1.0 --os_patch_level 2018-05-05 --ramdisk_offset 0x01000000 --tags_offset 0x00000100
../../../../out/host/linux-x86/bin/mkbootimg \
    --kernel "$IMAGE_GZ_DTB_TARGET" \
	--ramdisk "$RAMDISK_SOURCE" \
	--cmdline "androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_hsl_uart,0x78af000 androidboot.selinux=permissive buildvariant=eng" \
	--base 0x80000000 --pagesize 2048 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 \
	--output "$BOOT_RECOVERY_TARGET"

rm "$IMAGE_GZ_DTB_TARGET"
if [ -f "$BOOT_RECOVERY_TARGET" ]; then
	echo "    [i] Successfully built boot-recovery.img at $BOOT_RECOVERY_TARGET"
fi

echo "[#] Making recovery-installer.zip..."
cp -f "$RECOVERY_INSTALLER_TEMPLATE" "$OUT_DIR/$RECOVERY_INSTALLER_OUT"
cd $OUT_DIR
zip -u -1 -9 "$RECOVERY_INSTALLER_OUT" "$RAMDISK_FILE"
cd $SCRIPT_PATH
echo "    [i] Done"