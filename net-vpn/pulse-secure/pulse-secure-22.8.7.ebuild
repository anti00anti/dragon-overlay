# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RPM_COMPRESS_TYPE=none

inherit desktop rpm systemd xdg

MY_PV="$(ver_rs 2 r)-b48847"

DESCRIPTION="Ivanti Secure Access Client (formerly Pulse Secure)"
HOMEPAGE="https://www.ivanti.com/products/ivanti-secure-access-client"
SRC_URI="https://www.uwyo.edu/infotech/services/software/vpn/clients/version-${MY_PV}/ps-pulse-linux-${MY_PV}-installer.rpm"
S="${WORKDIR}"

LICENSE="Pulse-Secure-EULA"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip test"

QA_PREBUILT="opt/pulsesecure/*"

BDEPEND="
	dev-util/patchelf
"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-arch/zip
	app-misc/ca-certificates
	dev-cpp/atkmm:0
	dev-cpp/cairomm:0
	dev-cpp/glibmm:2
	dev-cpp/gtkmm:3.0
	dev-cpp/pangomm:1.4
	dev-libs/glib:2
	dev-libs/libbsd
	dev-libs/libsigc++:2
	dev-libs/nss[utils]
	dev-libs/openssl
	media-libs/harfbuzz
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dmidecode
	sys-apps/iproute2
	sys-apps/net-tools
	sys-apps/systemd
	sys-apps/util-linux
	sys-libs/zlib
	sys-process/procps
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/pango
"

src_prepare() {
	default

	einfo "Removing NULL DT_RUNPATH from libdispatch.so..."
	patchelf --remove-rpath opt/pulsesecure/lib/dispatch/libdispatch.so || die "patchelf failed for libdispatch.so"

	mv opt/pulsesecure/bin/pulseUI.webkit41 opt/pulsesecure/bin/pulseUI || die
	rm -f opt/pulsesecure/bin/pulseUI.webkit40 || die
	ln -s pulseUI opt/pulsesecure/bin/pulseUI.webkit41 || die

	if [[ -f usr/share/man/man1/pulse.1.gz ]]; then
		gzip -d usr/share/man/man1/pulse.1.gz || die
	fi

	find opt/pulsesecure/resource -type f -exec chmod 0644 {} + || die
	find opt/pulsesecure/lib -type f \( -name "*.txt" -o -name "*.ini" -o -name "*.conf" -o -name "tnc_config" \) -exec chmod 0644 {} + || die
}

src_install() {
	dodir /opt
	cp -pR opt/pulsesecure "${ED}/opt/" || die "Failed to install /opt/pulsesecure"

	systemd_dounit lib/systemd/system/pulsesecure.service

	domenu opt/pulsesecure/resource/pulse.desktop
	insinto /usr/share/dbus-1/system.d
	doins opt/pulsesecure/lib/JUNS/net.psecure.pulse.conf

	doman usr/share/man/man1/pulse.1

	dosym -r /opt/pulsesecure/bin/pulseUI /usr/bin/pulseUI
	dosym -r /opt/pulsesecure/bin/pulselauncher /usr/bin/pulselauncher

	dosym -r /etc/ssl/certs/ca-certificates.crt /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt

	keepdir /var/lib/pulsesecure/pulse
}

pkg_preinst() {
	xdg_pkg_preinst

	local legacy_trust="${EROOT}/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"
	if [[ -L ${legacy_trust} && $(readlink "${legacy_trust}") == "/etc/ssl/certs/ca-certificates.crt" ]]; then
		rm -f "${legacy_trust}" || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "To use Pulse Secure, the background service must be running:"
	if systemd_is_booted; then
		elog "  systemctl start pulsesecure.service"
		elog "To enable it at boot:"
		elog "  systemctl enable pulsesecure.service"
	else
		elog "  /opt/pulsesecure/bin/startup.sh start"
	fi
}
