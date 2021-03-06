NULL=

SUBDIRS= \
	$(NULL)

AM_CPPFLAGS = \
	-I$(srcdir) \
	-DPACKAGE_DATA_DIR=\""$(datadir)/lxpanel2"\" \
	-DPACKAGE_LIB_DIR=\""$(libdir)/lxpanel2"\" \
	-DPACKAGE_UI_DIR=\""$(datadir)/lxpanel2/ui"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	--include config.h \
	$(NULL)
# FIXME: --include config.h is not a cross-compiler solution and is gcc-only.

# The library for applet development -----------------------------------

lib_LTLIBRARIES=liblxpanel2-applet.la

VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-3.0 \
    --pkg gio-2.0 \
    --pkg gio-unix-2.0 \
    --pkg gmodule-2.0 \
    --pkg posix \
	--pkg lxpanel2-eggwrapbox \
	--pkg config \
	--vapidir=../vapi \
	--verbose \
	--thread \
	--library lxpanel2-applet \
	--header lxpanel2-applet.h \
	--vapi lxpanel2-applet.vapi \
	--disable-warnings \
	$(NULL)

# EggWrapBox from libegg
LIBEGG_SOURCES = \
	egg/eggwrapbox.c \
	egg/eggwrapbox-enums.c \
	$(NULL)

# later we should make applet development related
# files a separate library
liblxpanel2_applet_la_SOURCES = \
	applet.vala \
	button.vala \
	menu-button.vala \
	drawer.vala \
	popup.vala \
	gmarkup-dom.vala \
	utils.vala \
	module.vala \
	upower.vala \
	$(LIBEGG_SOURCES) \
	$(NULL)

liblxpanel2_applet_la_CFLAGS = \
    -Iegg \
	$(GTK_CFLAGS) \
	$(GIO_CFLAGS) \
	$(WNCK_CFLAGS) \
	$(GTOP_CFLAGS) \
	$(MENU_CACHE_CFLAGS) \
	$(X11_CFLAGS) \
	$(LIBFM_CFLAGS) \
	-Werror-implicit-function-declaration \
	$(ADDITIONAL_FLAGS) \
	-fPIC \
	-shared \
	$(NULL)

liblxpanel2_applet_la_LIBADD = \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

liblxpanel2_applet_la_LDFLAGS = \
	-export-dynamic \
	$(NULL)

liblxpanel2_applet_la_includedir = $(includedir)/lxpanel2
liblxpanel2_applet_la_include_HEADERS = \
	lxpanel2-applet.h \
	egg/eggwrapbox.h \
	egg/eggwrapbox-enums.h \
	$(NULL)

# install the vapi file
vapifiledir=$(datadir)/vala/vapi
vapifile_DATA = \
	lxpanel2-applet.vapi \
	lxpanel2-applet.deps \
	../vapi/lxpanel2-eggwrapbox.vapi \
	$(NULL)

# install a pkg-config file
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = \
	lxpanel2-applet.pc \
	$(NULL)

# Workarounds to force the build of some source files before compiling
BUILT_SOURCES= \
	$(NULL)

# clean these files during make clean
CLEANFILES = \
	$(BUILT_SOURCES) \
	lxpanel2-applet.vapi \
	$(NULL)

EXTRA_DIST = \
	lxpanel2-applet.deps \
	$(NULL)
