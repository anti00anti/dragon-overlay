# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RPM_COMPRESS_TYPE=none

inherit desktop rpm systemd xdg

DESCRIPTION="Ivanti Secure Access Client (formerly Pulse Secure)"
HOMEPAGE="https://www.ivanti.com/products/ivanti-secure-access-client"
SRC_URI="https://www.uwyo.edu/infotech/services/software/vpn/clients/version-22.8r7-b48847/ps-pulse-linux-22.8r7-b48847-installer.rpm"
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
	app-misc/ca-certificates
	dev-cpp/gtkmm:3.0
	dev-libs/libbsd
	net-libs/webkit-gtk:4.1
	sys-apps/dmidecode
	sys-apps/net-tools
	sys-apps/util-linux
	x11-libs/libX11
	|| (
		sys-apps/systemd
		sys-apps/systemd-utils
	)
"

src_prepare() {
	default

	einfo "Removing NULL DT_RUNPATH from libdispatch.so..."
	patchelf --remove-rpath opt/pulsesecure/lib/dispatch/libdispatch.so || die "patchelf failed for libdispatch.so"

	# Use the WebKitGTK 4.1 UI binary and remove the obsolete WebKitGTK 4.0 binary
	mv opt/pulsesecure/bin/pulseUI.webkit41 opt/pulsesecure/bin/pulseUI || die
	rm -f opt/pulsesecure/bin/pulseUI.webkit40 || die
	ln -s pulseUI opt/pulsesecure/bin/pulseUI.webkit41 || die

	# Decompress man page for doman
	if [[ -f usr/share/man/man1/pulse.1.gz ]]; then
		gzip -d usr/share/man/man1/pulse.1.gz || die
	fi

	# Fix non-executable file permissions on resources and configs
	find opt/pulsesecure/resource -type f -exec chmod 0644 {} + || die
	find opt/pulsesecure/lib -type f \( -name "*.txt" -o -name "*.ini" -o -name "*.conf" \) -exec chmod 0644 {} + || die
}

src_install() {
	# Install application files into /opt
	dodir /opt
	cp -a opt/pulsesecure "${ED}/opt/" || die "Failed to install /opt/pulsesecure"

	# Systemd service unit
	systemd_dounit lib/systemd/system/pulsesecure.service

	# Desktop entry and D-Bus system policy
	domenu opt/pulsesecure/resource/pulse.desktop
	insinto /usr/share/dbus-1/system.d
	doins opt/pulsesecure/lib/JUNS/net.psecure.pulse.conf

	# Man page
	doman usr/share/man/man1/pulse.1

	# Convenience symlinks in PATH
	dosym -r /opt/pulsesecure/bin/pulseUI /usr/bin/pulseUI
	dosym -r /opt/pulsesecure/bin/pulselauncher /usr/bin/pulselauncher

	# Certificate trust bundle compatibility symlink
	dosym -r /etc/ssl/certs/ca-certificates.crt /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt

	# Configuration state directory
	keepdir /var/lib/pulsesecure/pulse
}

pkg_preinst() {
	xdg_pkg_preinst

	# Clean up untracked legacy symlink created by older ebuild versions
	local legacy_trust="${EROOT}/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"
	if [[ -L ${legacy_trust} ]]; then
		rm -f "${legacy_trust}"
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

pkg_postrm() {
	xdg_pkg_postrm
}
