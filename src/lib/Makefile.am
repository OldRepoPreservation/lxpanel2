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

lib_LTLIBRARIES=liblxpanel-applet.la

liblxpanel_applet_la_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-3.0 \
    --pkg gio-2.0 \
    --pkg gio-unix-2.0 \
    --pkg gmodule-2.0 \
    --pkg posix \
	--pkg libwnck-3.0 \
	--pkg x11 \
	--pkg eggwrapbox \
	--pkg menu-cache \
	--pkg na-tray \
	--pkg config \
	--pkg gtop-2.0 \
	--vapidir ../vapi \
	--verbose \
	--thread \
	--vapi lxpanel-applet.vapi \
	--header lxpanel-applet.h \
	$(NULL)
#	--disable-warnings

# EggWrapBox from libegg
LIBEGG_SOURCES = \
	egg/eggwrapbox.c \
	egg/eggwrapbox-enums.c \
	$(NULL)

# later we should make applet development related
# files a separate library
liblxpanel_applet_la_SOURCES = \
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

liblxpanel_applet_la_CFLAGS = \
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

liblxpanel_applet_la_LIBADD = \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

liblxpanel_applet_la_LDFLAGS = \
	-export-dynamic \
	$(NULL)

liblxpanel_applet_la_includedir = $(includedir)/lxpanel2
liblxpanel_applet_la_include_HEADERS = lxpanel-applet.h


# Workarounds to force the build
BUILT_SOURCES= \
	$(NULL)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)

EXTRA_DIST = \
	lxpanel2.deps \
	$(NULL)
