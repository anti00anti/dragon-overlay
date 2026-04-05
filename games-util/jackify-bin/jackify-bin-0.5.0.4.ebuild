# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
inherit desktop python-single-r1 xdg

DESCRIPTION="Simplifying Wabbajack modlist installation and configuration on Linux"
HOMEPAGE="https://github.com/Omni-guides/Jackify"
SRC_URI="https://github.com/Omni-guides/Jackify/releases/download/v${PV}/Jackify.AppImage -> ${P}.AppImage"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="strip"

RDEPEND="
	${PYTHON_DEPS}
	dev-util/lttng-ust-compat
	$(python_gen_cond_dep '
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/pycryptodome[${PYTHON_USEDEP}]
		dev-python/pyside[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/tqdm[${PYTHON_USEDEP}]
		dev-python/vdf[${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="sys-fs/fuse:0"

S="${WORKDIR}"

src_unpack() {
	cp "${DISTDIR}/${P}.AppImage" "${WORKDIR}/" || die
	chmod a+x "${WORKDIR}/${P}.AppImage" || die
	# Extract the AppImage
	"${WORKDIR}/${P}.AppImage" --appimage-extract || die
}

src_prepare() {
	default

	# Remove __pycache__ files
	find squashfs-root/ -type d -name '__pycache__' -exec rm -r {} + || die

	# Remove bundled Python libraries to force use of system deps
	rm -rf squashfs-root/usr/lib || die
}

src_install() {
	python_setup

	# Install the module and engine files
	insinto /opt
	doins -r squashfs-root/opt/jackify
	doins -r squashfs-root/opt/jackify-engine

	# Preserve empty directories that doins -r omits
	while IFS= read -r -d '' dir; do
		keepdir "/${dir#squashfs-root/}"
	done < <(find squashfs-root/opt -type d -empty -print0)

	# Fix permissions
	fperms +x /opt/jackify/frontends/gui/__main__.py
	find "${ED}/opt/jackify-engine/Extractors/linux-x64/" -type f -exec chmod +x {} + || die
	find "${ED}/opt/jackify/tools/" -type f -exec chmod +x {} + || die

	# Install icon and desktop file
	insinto /usr/share/icons/hicolor/256x256/apps
	newins squashfs-root/usr/share/icons/hicolor/256x256/apps/com.jackify.app.png com.jackify.app.png
	newmenu squashfs-root/com.jackify.app.desktop jackify.desktop

	# Create wrapper script dynamically using Gentoo's selected python target
	cat <<- EOF > "${T}/jackify"
	#!/bin/bash
	# Set up Jackify directory structure in user's home
	JACKIFY_HOME="\${HOME}/Jackify"
	mkdir -p "\${JACKIFY_HOME}"/{temp,logs,cache,engine,.tmp}

	# Copy jackify-engine to writable location if needed
	ENGINE_SOURCE_DIR="/opt/jackify-engine"
	ENGINE_TARGET="\${JACKIFY_HOME}/jackify-engine/jackify-engine"

	UPDATE_ENGINE=false
	if [ ! -f "\${ENGINE_TARGET}" ]; then
	    UPDATE_ENGINE=true
	elif [ "\${ENGINE_SOURCE_DIR}/jackify-engine" -nt "\${ENGINE_TARGET}" ]; then
	    UPDATE_ENGINE=true
	fi

	if [ "\${UPDATE_ENGINE}" = true ]; then
	    echo "Copying jackify-engine to writable location..."
	    if [ -d "\${ENGINE_SOURCE_DIR}" ]; then
	        rm -rf "\${JACKIFY_HOME}/engine"
	        cp -r "\${ENGINE_SOURCE_DIR}" "\${JACKIFY_HOME}/"
	        chmod +x "\${ENGINE_TARGET}"
	        chmod +x "\${JACKIFY_HOME}/engine/Extractors/linux-x64/"* 2>/dev/null || true
	    fi
	fi

	export APPDIR="/"
	export PYTHONPATH="/opt:\${PYTHONPATH}"
	export JACKIFY_ENGINE_PATH="\${ENGINE_TARGET}"
	exec ${EPYTHON} -m jackify.frontends.gui "\$@"
	EOF

	exeinto /usr/bin
	doexe "${T}/jackify"
}
