# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1 git-r3

DESCRIPTION="MSI Embedded Controller (EC) kernel module for battery and fan control"
HOMEPAGE="https://github.com/BeardOverflow/msi-ec"
EGIT_REPO_URI="https://github.com/BeardOverflow/msi-ec.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

DEPEND="virtual/linux-sources"
RDEPEND=""

CONFIG_CHECK="~ACPI ~ACPI_BATTERY"

src_compile() {
	local modlist=( ${PN}="kernel/drivers/platform/x86:." )
	local modargs=( KDIR="${KV_OUT_DIR}" KERNELRELEASE="${KV_FULL}" )
	linux-mod-r1_src_compile
}
