do_install:append:class-native() {
	sed -i 's/,64bit//g' "${D}${sysconfdir}/mke2fs.conf"
}
