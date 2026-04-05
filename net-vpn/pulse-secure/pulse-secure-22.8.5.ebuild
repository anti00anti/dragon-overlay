# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm xdg

DESCRIPTION="Ivanti Secure Access Client (formerly Pulse Secure)"
HOMEPAGE="https://www.ivanti.com/products/ivanti-secure-access-client"
SRC_URI="https://dl.vpn.ucsb.edu/clients/Linux%20VPN%20Client/ps-pulse-linux-22.8r5-b41063-installer.rpm"

S="${WORKDIR}"

LICENSE="Pulse-Secure-EULA"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip test bindist"

QA_PREBUILT="opt/pulsesecure/*"

# We need patchelf at build-time to fix the broken RPATH in the proprietary binary
BDEPEND="
dev-util/patchelf
"

RDEPEND="
dev-cpp/gtkmm:3.0
net-libs/webkit-gtk:4
sys-apps/dmidecode
sys-apps/net-tools
app-misc/ca-certificates
"

src_unpack() {
	rpm_unpack ${A}
}

src_prepare() {
	default

	einfo "Removing NULL DT_RUNPATH from libdispatch.so..."
	patchelf --remove-rpath opt/pulsesecure/lib/dispatch/libdispatch.so || die "Failed to patch libdispatch.so"
}

src_install() {
	dodir /opt
	cp -a opt/pulsesecure "${ED}/opt/" || die "Failed to copy /opt/pulsesecure"
	cp -a lib "${ED}/lib/" || die "Failed to copy /lib"
	cp -a usr "${ED}/usr/" || die "Failed to copy /usr"

	if [[ -f "${ED}/usr/share/man/man1/pulse.1.gz" ]]; then
		gunzip "${ED}/usr/share/man/man1/pulse.1.gz" || die "Failed to decompress pulse.1.gz"
	fi

	dodir /var/lib/pulsesecure/pulse
	keepdir /var/lib/pulsesecure/pulse

	fowners -R root:root /opt/pulsesecure
}

pkg_postinst(){
	if [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
		dodir /etc/pki/ca-trust/extracted/openssl
		ln -fs /etc/ssl/certs/ca-certificates.crt /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
	fi
}

pkg_postrm(){
	if [[ -f /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt ]]; then
		rm /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
	fi
}
