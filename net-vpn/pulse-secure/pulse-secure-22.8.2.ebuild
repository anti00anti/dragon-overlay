# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg-utils rpm

DESCRIPTION="Ivanti Secure Access Client"
HOMEPAGE="https://www.pulsesecure.net/"
SRC_URI="https://dl.vpn.ucsb.edu/clients/Linux%20VPN%20Client/ps-pulse-linux-22.8r2-b33497-installer.rpm"

S="${WORKDIR}"

LICENSE="Pulse-Secure-EULA"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test"

RDEPEND="
		dev-cpp/gtkmm:3.0
		net-libs/webkit-gtk:4/37
		sys-apps/dmidecode
"

src_unpack() {
	rpm_src_unpack ${A}
}

src_install() {
	cp -R "${S}/opt" "${D}/" || die
	cp -R "${S}/lib" "${D}/" || die
	cp -R "${S}/usr" "${D}/" || die
}

pkg_postinst(){
	xdg_desktop_database_update
}

pkg_postrm(){
	xdg_desktop_database_update
}
