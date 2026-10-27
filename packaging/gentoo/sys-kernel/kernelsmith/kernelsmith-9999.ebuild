# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.85.0"

EGIT_REPO_URI="https://github.com/firesand/kernelsmith.git"

inherit cargo desktop git-r3 optfeature xdg

DESCRIPTION="Guided, hardware-aware custom kernel builder with a Steam-style GUI"
HOMEPAGE="https://github.com/firesand/kernelsmith"

LICENSE="GPL-2+"
# Dependent crate licenses (from Cargo.lock / cargo metadata)
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 CC0-1.0 ISC
	MIT MPL-2.0 OFL-1.1 UbuntuFontLicense-1.0 Unicode-3.0 Unlicense ZLIB
"

SLOT="0"
KEYWORDS=""

# Kernelsmith drives kernel builds, so the kernel's own build requirements are
# runtime dependencies here. Clang/LLVM, pahole, perf and modprobed-db are
# optional and detected at runtime (see pkg_postinst).
RDEPEND="
	app-alternatives/cpio
	dev-lang/perl
	dev-libs/openssl
	dev-libs/wayland
	media-libs/libglvnd
	sys-auth/polkit
	sys-devel/bc
	sys-devel/bison
	sys-devel/flex
	sys-devel/patch
	sys-kernel/installkernel
	virtual/libelf
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libxkbcommon[X]
	x11-misc/xdg-utils
	|| ( net-misc/curl net-misc/wget )
"

QA_FLAGS_IGNORED="usr/bin/kernelsmith"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_configure() {
	cargo_src_configure --locked
}

src_install() {
	cargo_src_install --path crates/app

	domenu packaging/kernelsmith.desktop
	doicon -s scalable packaging/kernelsmith.svg

	# pkexec shows this action's message when a build or uninstall asks for
	# the administrator password.
	sed "s|@BINDIR@|${EPREFIX}/usr/bin|" packaging/org.kernelsmith.policy \
		> "${T}"/org.kernelsmith.policy || die
	insinto /usr/share/polkit-1/actions
	doins "${T}"/org.kernelsmith.policy

	dodoc README.md
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "Clang builds, ThinLTO and AutoFDO" "llvm-core/clang llvm-core/lld"
	optfeature "sched_ext and BTF support" dev-util/pahole
	optfeature "AutoFDO profiling" dev-util/perf
	optfeature "safer driver trimming from long-term module history" sys-kernel/modprobed-db
	optfeature "runtime-switchable BPF schedulers" sys-kernel/scx

	elog "Kernelsmith needs full kernel sources (e.g. sys-kernel/gentoo-sources);"
	elog "the *-dist trees that distribution kernels install only hold headers."
	elog "Kernels it builds are recorded in /var/lib/kernelsmith and removed from"
	elog "its Library page; unmerging this package leaves them installed."
}
