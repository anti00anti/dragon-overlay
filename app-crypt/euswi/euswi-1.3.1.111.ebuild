# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib udev

DESCRIPTION="IIT End User CA-1. Sign (web)"
HOMEPAGE="https://iit.com.ua"
SRC_URI="
	amd64? ( https://iit.com.ua/download/productfiles/euswi.64.tar -> ${P}_amd64.tar )
	x86? ( https://iit.com.ua/download/productfiles/euswi.tar -> ${P}_x86.tar )
"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="bindist mirror"

RDEPEND="
	sys-apps/pcsc-lite
	x11-libs/gtk+:3
"
BDEPEND="dev-util/patchelf"

QA_PREBUILT="opt/iit/eu/sw/*"

src_prepare() {
	default

	rm opt/iit/eu/sw/install.sh opt/iit/eu/sw/uninstall.sh || die

	patchelf --clear-execstack opt/iit/eu/sw/libav337p11d.so || die
}

src_install() {
	insinto /opt
	doins -r opt/iit

	fperms 0755 /opt/iit/eu/sw/euscpnmh
	fperms 0644 /opt/iit/eu/sw/osplm.ini

	udev_dorules etc/udev/rules.d/60-iit-e-keys.rules

	insinto /etc/chromium/native-messaging-hosts
	newins "${FILESDIR}/chrome.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json

	insinto /etc/opt/chrome/native-messaging-hosts
	newins "${FILESDIR}/chrome.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json

	insinto /usr/$(get_libdir)/mozilla/native-messaging-hosts
	newins "${FILESDIR}/mozilla.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json

	if [[ $(get_libdir) != "lib" ]]; then
		insinto /usr/lib/mozilla/native-messaging-hosts
		newins "${FILESDIR}/mozilla.ua.com.iit.eusign.nmh.json" ua.com.iit.eusign.nmh.json
	fi

	dosym -r /opt/iit/eu/sw/libav337p11d.so /usr/$(get_libdir)/libav337p11d.so
	dosym -r /opt/iit/eu/sw/npeuscp.so /usr/$(get_libdir)/mozilla/plugins/npeuscp.so
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
