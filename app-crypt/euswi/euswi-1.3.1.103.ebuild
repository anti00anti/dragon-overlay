# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="IIT End User CA-1. Sign (web)"
HOMEPAGE="https://iit.com.ua"

SRC_URI="
amd64? ( https://iit.com.ua/download/productfiles/euswi.64.tar -> ${P}_amd64.tar )
x86? ( https://iit.com.ua/download/productfiles/euswi.tar -> ${P}_x86.tar )
"

S="${WORKDIR}"

SLOT="0"
KEYWORDS="-* ~amd64 ~x86"

BDEPEND="dev-util/patchelf"

RDEPEND="
sys-apps/pcsc-lite
"

QA_PREBUILT="opt/iit/eu/sw/*"

src_unpack() {
	if use amd64; then
		unpack ${P}_amd64.tar
	elif use x86; then
		unpack ${P}_x86.tar
	fi
}

src_install() {

	dodir /opt
	cp -a "${S}/opt/iit" "${ED}/opt/" || die "Failed to copy /opt/iit"

	udev_dorules "${S}/etc/udev/rules.d/60-iit-e-keys.rules"

	patchelf --clear-execstack "${ED}/opt/iit/eu/sw/libav337p11d.so" || die "patchelf failed to clear execstack"

	rm "${ED}/opt/iit/eu/sw/install.sh" "${ED}/opt/iit/eu/sw/uninstall.sh" || die

	insinto /etc/opt/chrome/native-messaging-hosts
	newins "${FILESDIR}/chrome.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json

	insinto /etc/chromium/native-messaging-hosts
	newins "${FILESDIR}/chrome.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json

	insinto /usr/lib/mozilla/native-messaging-hosts
	doins "${FILESDIR}/mozilla.ua.com.iit.eusign.nmh.json"

	dodir /usr/lib/mozilla/plugins
	dosym ../../../../opt/iit/eu/sw/npeuscp.so /usr/lib/mozilla/plugins/npeuscp.so

	dodir /usr/lib
	dosym ../../opt/iit/eu/sw/libav337p11d.so /usr/lib/libav337p11d.so
}

pkg_postinst() {
	udev_reload
	"${ROOT}"/opt/iit/eu/sw/euscpnmh /install
}

pkg_postrm() {
	udev_reload
	"${ROOT}"/opt/iit/eu/sw/euscpnmh /uninstall
}
