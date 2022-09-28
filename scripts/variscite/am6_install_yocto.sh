#!/bin/bash -e

. /usr/bin/echos.sh

IMGS_PATH=/opt/images/Yocto
ROOTFSPART=2
PART=p
ROOTFS_IMAGE=rootfs.tar.xz

check_board()
{
	if grep -q "AM62X" /sys/devices/soc0/family; then
		BOARD=am62x-var-som
		EMMC_BLOCK=mmcblk0
		SD_BLOCK=mmcblk1
	else
		red_bold_echo "ERROR: Unsupported board"
		exit 1
	fi


	if [[ ! -b /dev/${EMMC_BLOCK} ]] ; then
		red_bold_echo "ERROR: Can't find eMMC device (/dev/${EMMC_BLOCK})."
		red_bold_echo "Please verify you are using the correct options for your SOM."
		exit 1
	fi

	DRIVE="/dev/${EMMC_BLOCK}"
}

delete_emmc()
{
	echo
	blue_underlined_bold_echo "Deleting current partitions"

	umount /dev/${EMMC_BLOCK}${PART}* 2>/dev/null || true

	for ((i=1; i<=16; i++)); do
		if [[ -e /dev/${EMMC_BLOCK}${PART}${i} ]]; then
			dd if=/dev/zero of=/dev/${EMMC_BLOCK}${PART}${i} bs=1M count=1 2>/dev/null || true
		fi
	done
	sync

	# Zero out first 100MB
	dd if=/dev/zero of=/dev/${EMMC_BLOCK} bs=1M count=100

	sync; sleep 1
}

create_emmc_parts()
{
	dd if=/dev/zero of=$DRIVE bs=1024 count=1024

	SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`
	echo DISK SIZE - $SIZE bytes

	(
	 echo n; echo p; echo 1; echo; echo +128M; \
	 echo n; echo p; echo 2; echo 276480; echo; echo t; echo 1; echo c; echo a; echo 1; echo w;
	) | fdisk -u /dev/${EMMC_BLOCK} > /dev/null

	sync; sleep 1
	fdisk -u -l /dev/${EMMC_BLOCK}
}

format_emmc_parts()
{
	echo
	blue_underlined_bold_echo "Formatting partitions"

	mkfs.vfat -F 32 -n "boot" /dev/${EMMC_BLOCK}${PART}1
	mkfs.ext4 /dev/${EMMC_BLOCK}${PART}${ROOTFSPART} -L rootfs

	sync; sleep 1
}

install_bootloader_to_emmc()
{
	echo
	blue_underlined_bold_echo "Installing booloader"

	# Mount SD and eMMC boot partitions
	mkdir -p .sd_boot .emmc_boot
	mount /dev/${SD_BLOCK}${PART}1 .sd_boot
	mount /dev/${EMMC_BLOCK}${PART}1 .emmc_boot

	# Copy files to EMMC boot partition
	cp .sd_boot/* .emmc_boot/

	# Cleanup
	umount .sd_boot
	umount .emmc_boot
	rm -rf .sd_boot .emmc_boot
	sync
}

install_rootfs_to_emmc()
{
	echo
	blue_underlined_bold_echo "Installing rootfs"

	MOUNTDIR=/run/media/${EMMC_BLOCK}${PART}${ROOTFSPART}
	mkdir -p ${MOUNTDIR}
	mount /dev/${EMMC_BLOCK}${PART}${ROOTFSPART} ${MOUNTDIR}

	printf "Extracting files"
	tar --warning=no-timestamp -xpf ${IMGS_PATH}/${ROOTFS_IMAGE} -C ${MOUNTDIR} --checkpoint=.1200

	# Adjust u-boot-fw-utils for eMMC on the installed rootfs
	if [ -f ${MOUNTDIR}/etc/fw_env.config ]; then
		sed -i "s/\/dev\/mmcblk./\/dev\/${EMMC_BLOCK}/" ${MOUNTDIR}/etc/fw_env.config
	fi

	echo
	sync

	umount ${MOUNTDIR}
}

check_board
delete_emmc
create_emmc_parts
format_emmc_parts
install_bootloader_to_emmc
install_rootfs_to_emmc
