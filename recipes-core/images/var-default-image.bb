SUMMARY = "Variscite SDK full filesystem image"

DESCRIPTION = "Complete Variscite SDK filesystem image based on tisdk-default-image."

require ../../../meta-arago/meta-arago-distro/recipes-core/images/arago-image.inc

SPLASH = "${@bb.utils.contains('MACHINE_FEATURES','gpu','psplash','',d)}"

IMAGE_INSTALL += "\
    packagegroup-arago-base \
    packagegroup-arago-console \
    packagegroup-arago-base-tisdk \
    ti-test \
    ${@bb.utils.contains('MACHINE_FEATURES','gpu','packagegroup-arago-tisdk-graphics','',d)} \
    ${@['','packagegroup-arago-tisdk-opencl'][oe.utils.all_distro_features(d, 'opencl', True, False) and bb.utils.contains('MACHINE_FEATURES', 'dsp', True, False, d)]} \
    packagegroup-arago-tisdk-connectivity \
    packagegroup-arago-tisdk-crypto \
    packagegroup-arago-tisdk-multimedia \
    packagegroup-arago-tisdk-amsdk \
    ${@bb.utils.contains('MACHINE_FEATURES','gpu','packagegroup-arago-tisdk-hmi','packagegroup-arago-base-tisdk-server-extra',d)} \
    ti-analytics \
    ti-demos \
    var-mii \
"

export IMAGE_BASENAME = "${PN}"

OPENCL = " \
    ${@bb.utils.contains('MACHINE_FEATURES','dsp','ti-opencl','',d)} \
    ${@bb.utils.contains('MACHINE_FEATURES','dsp','packagegroup-arago-tisdk-opencl-extra','',d)} \
"

IMAGE_INSTALL += "\
    ${@oe.utils.all_distro_features(d, "opencl", "${OPENCL}")} \
    ${@bb.utils.contains('TUNE_FEATURES', 'armv7a', 'valgrind', '', d)} \
    docker \
"

PR_append = ".tisdk1"

IMAGE_INSTALL_append_am62xx += "\
    packagegroup-dl \
    libcamera \
    resize-rootfs \
"

WIC_CREATE_EXTRA_ARGS += " --no-fstab-update"
# Extra boot files for WIC images
do_image_wic_append_am62xx-evm[depends] += " wifi-oob:do_deploy"
IMAGE_BOOT_FILES_append_am62xx-evm += " wificfg"
