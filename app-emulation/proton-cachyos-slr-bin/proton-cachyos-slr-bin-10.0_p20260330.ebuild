# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="${PV/_p/-}"
_internal_name="proton-cachyos-${MY_PV}-slr"

DESCRIPTION="Compatibility tool for Steam Play based on Wine and additional components (CachyOS SLR)"
HOMEPAGE="https://github.com/CachyOS/proton-cachyos"
SRC_URI="https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-${MY_PV}-slr/proton-cachyos-${MY_PV}-slr-x86_64.tar.xz"

# CachyOS Proton uses a mix of licenses derived from Wine, DXVK, and others
LICENSE="custom BSD MPL-2.0 LGPL-2.1 MIT ZLIB"
SLOT="${PV}"
KEYWORDS="~amd64"
RESTRICT="mirror strip"

QA_PREBUILT="*"

RDEPEND="
	media-libs/mesa[vulkan,abi_x86_32]
	media-libs/vulkan-loader[abi_x86_32]
"

S="${WORKDIR}"

src_install() {
	local extracted_dir
	# Find the directory extracted from the tar.xz file dynamically
	extracted_dir="$(find "${WORKDIR}" -maxdepth 1 -type d -name "proton-cachyos-*" -print -quit)"

	if [[ ! -d "${extracted_dir}" ]]; then
		die "Could not find the extracted Proton directory."
	fi

	# Create the standard Steam compatibility tools directory system-wide
	dodir "/usr/share/steam/compatibilitytools.d/${_internal_name}"

	# Copy all contents over while preserving execution permissions 
	cp -a "${extracted_dir}"/. "${ED}/usr/share/steam/compatibilitytools.d/${_internal_name}/" || die "Failed to copy files"
}

pkg_postinst() {
	elog "Proton-CachyOS-SLR has been installed to:"
	elog "  /usr/share/steam/compatibilitytools.d/${_internal_name}"
	elog ""
	elog "To use it:"
	elog "  1. Restart your Steam client."
	elog "  2. Right-click a game -> Properties -> Compatibility."
	elog "  3. Check 'Force the use of a specific Steam Play compatibility tool'."
	elog "  4. Select '${_internal_name}' from the drop-down list."
	elog ""
	elog "Note: For optimal compatibility, ensure your system has necessary 32-bit graphics/audio libraries enabled."
}
