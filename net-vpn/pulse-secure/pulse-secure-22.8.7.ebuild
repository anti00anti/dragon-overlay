# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm xdg

DESCRIPTION="Ivanti Secure Access Client (formerly Pulse Secure)"
HOMEPAGE="https://www.ivanti.com/products/ivanti-secure-access-client"
SRC_URI="https://www.uwyo.edu/infotech/services/software/vpn/clients/version-22.8r7-b48847/ps-pulse-linux-22.8r7-b48847-installer.rpm"

S="${WORKDIR}"

LICENSE="Pulse-Secure-EULA"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test bindist"

QA_PREBUILT="opt/pulsesecure/*"

BDEPEND="
	dev-util/patchelf
"

RDEPEND="
	app-misc/ca-certificates
	dev-cpp/gtkmm:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dmidecode
	sys-apps/net-tools
"

src_prepare() {
	default

	einfo "Removing NULL DT_RUNPATH from libdispatch.so..."
	patchelf --remove-rpath opt/pulsesecure/lib/dispatch/libdispatch.so || die "patchelf failed for libdispatch.so"
}

src_install() {
	dodir /opt
	cp -a opt/pulsesecure "${ED}/opt/" || die "Failed to install /opt/pulsesecure"
	cp -a lib "${ED}/lib/" || die "Failed to install /lib"
	rm -rf -- "${ED}/lib/.build-id" || die "Failed to remove /lib/.build-id"
	cp -a usr "${ED}/usr/" || die "Failed to install /usr"
	rm -f -- "${ED}/opt/pulsesecure/bin/pulseUI.webkit40" || die "Failed to remove pulseUI.webkit40"
	dosym /opt/pulsesecure/bin/pulseUI.webkit41 /opt/pulsesecure/bin/pulseUI

	if [[ -f "${ED}/usr/share/man/man1/pulse.1.gz" ]]; then
		gunzip "${ED}/usr/share/man/man1/pulse.1.gz" || die "Failed to decompress pulse.1.gz"
	fi

	dodir /var/lib/pulsesecure/pulse
	keepdir /var/lib/pulsesecure/pulse

	fowners -R root:root /opt/pulsesecure
}

	pkg_postinst() {
	local cert_bundle=/etc/ssl/certs/ca-certificates.crt
	local trust_bundle=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt

	if [[ -f ${cert_bundle} && ! -e ${trust_bundle} && ! -L ${trust_bundle} ]]; then
		mkdir -p "${trust_bundle%/*}" || die "Failed to create certificate trust directory"
		ln -s "${cert_bundle}" "${trust_bundle}" || die "Failed to link certificate bundle"
	fi
}

pkg_postrm() {
	local trust_bundle=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt

	if [[ -L ${trust_bundle} && $(readlink "${trust_bundle}") == /etc/ssl/certs/ca-certificates.crt ]]; then
		rm -f -- "${trust_bundle}" || die "Failed to remove certificate bundle link"
	fi
}
