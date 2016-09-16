# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-embedded/arduino/arduino-1.0.5.ebuild,v 1.3 2013/08/18 13:27:34 ago Exp $

EAPI=4
JAVA_PKG_IUSE="doc examples"

inherit eutils java-pkg-2 java-ant-2

DESCRIPTION="An open-source AVR electronics prototyping platform"
HOMEPAGE="http://arduino.cc/ http://arduino.googlecode.com/"
SRC_URI="https://github.com/${PN}/Arduino/archive/${PV}.tar.gz mirror://gentoo/arduino-icons.tar.bz2"
LICENSE="GPL-2 GPL-2+ LGPL-2 CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="strip binchecks"
IUSE=""

COMMONDEP=""

RDEPEND="${COMMONDEP}
dev-embedded/avrdude
sys-devel/crossdev
>=virtual/jre-1.5"

DEPEND="${COMMONDEP}
>=virtual/jdk-1.5"

EANT_EXTRA_ARGS="-Dversion=${PV}"
EANT_BUILD_TARGET="build"

src_unpack(){
	unpack ${A}
	cd ../"${S}"
	mv Arduino-${PV} ${PN}-${PV}
}

java_prepare() {
	# Patch build.xml
	epatch "${FILESDIR}"/${PN}-${PV}-build.xml.patch

	# Patch platform.txt
	epatch "${FILESDIR}"/${PN}-${PV}-platform.txt.patch
}

src_compile() {
	eant "${EANT_EXTRA_ARGS}" -f build/build.xml
}

src_install() {
	cd "${S}"/build/linux/work || die

	insinto /usr/share/${PN}/
	doins -r dist hardware lib libraries tools revisions.txt
	fowners -R root:uucp /usr/share/${PN}/hardware
	
	# tools/avr
	dodir /usr/share/${PN}/hardware/tools/avr
	dodir /usr/share/${PN}/hardware/tools/avr/avr
	dosym /usr/avr/include /usr/share/${PN}/hardware/tools/avr/avr/include
	dosym /usr/avr/lib /usr/share/${PN}/hardware/tools/avr/avr/lib
	dodir /usr/share/${PN}/hardware/tools/avr/avr/bin
	for f in `ls /usr/libexec/gcc/avr/`; do
	    dosym /usr/libexec/gcc/avr/$f /usr/share/${PN}/hardware/tools/avr/avr/bin/$f
	done
	dosym /usr/bin /usr/share/${PN}/hardware/tools/avr/bin
	dodir /usr/share/${PN}/hardware/tools/avr/etc
	dosym /etc/avrdude.conf /usr/share/${PN}/hardware/tools/avr/etc/avrdude.conf
	dosym /usr/include /usr/share/${PN}/hardware/tools/avr/include
	dosym /usr/lib /usr/share/${PN}/hardware/tools/avr/lib
	dosym /usr/libexec /usr/share/${PN}/hardware/tools/avr/libexec
	
	doins arduino
	fperms 755 /usr/share/${PN}/arduino
	dosym /usr/share/${PN}/arduino /usr/bin/arduino 
	
	if use examples; then
		java-pkg_doexamples examples
		docompress -x /usr/share/doc/${P}/examples/
	fi

	if use doc; then
		dodoc revisions.txt "${S}"/README.md
		dohtml -r reference
		dosym /usr/share/doc/${PN}-${PV}/html/reference /usr/share/${PN}/reference
		java-pkg_dojavadoc "${S}"/build/javadoc/everything
	fi

	# install menu and icons
	domenu "${FILESDIR}/${PN}.desktop"
	for sz in 16 24 32 48 128 256; do
		newicon -s $sz \
			"${WORKDIR}/${PN}-icons/debian_icons_${sz}x${sz}_apps_${PN}.png" \
			"${PN}.png"
	done
}

pkg_postinst() {
	[ ! -x /usr/bin/avr-g++ ] && ewarn "Missing avr-g++; you need to crossdev -s4 avr"
}
