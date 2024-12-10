# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 git-r3

DESCRIPTION="The module implements a basic interface to the IVSHMEM device for Looking Glass"
HOMEPAGE="https://looking-glass.io https://github.com/gnif/LookingGlass"

EGIT_REPO_URI="https://github.com/gnif/LookingGlass.git"

LICENSE="GPL-2"
SLOT="0"

src_compile() {
	local modlist=( ${PN}="kernel/drivers/misc:module" )
	local modargs=( KVER="${KV_FULL}" KDIR="${KV_OUT_DIR}" )

	linux-mod-r1_src_compile
}
