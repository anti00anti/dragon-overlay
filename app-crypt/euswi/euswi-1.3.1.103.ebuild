# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="IIT End User CA-1. Sign (web)"
HOMEPAGE="http://iit.com.ua"
SRC_URI="https://iit.com.ua/download/productfiles/euswi.64.tar -> ${P}.tar"

#LICENSE=""

S="${WORKDIR}"

SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test"

DEPEND="sys-apps/pcsc-lite"
RDEPEND="${DEPEND}"

src_install() {
	default
	cp -R "${S}/opt" "${D}/" || die
	udev_dorules "etc/udev/rules.d/60-iit-e-keys.rules"
}

pkg_postinst() {
	"${ROOT}"/opt/iit/eu/sw/install.sh
}

pkg_prerm() {
	"${ROOT}"/opt/iit/eu/sw/unistall.sh
}
