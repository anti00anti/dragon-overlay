# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 git-r3

DESCRIPTION="Kernel module for the embedded controller of MSI laptops."
HOMEPAGE="https://github.com/BeardOverflow/msi-ec"
EGIT_REPO_URI="https://github.com/BeardOverflow/msi-ec.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

src_compile() {
	local modlist=( ${PN}="kernel/drivers/platform/x86:." )
	local modargs=( KVER="${KV_FULL}" KDIR="${KV_OUT_DIR}" )
	linux-mod-r1_src_compile
}
