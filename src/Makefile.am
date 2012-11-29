NULL=

SUBDIRS= \
	lib \
	applets/battery \
	applets/sample \
	$(NULL)

AM_CPPFLAGS = \
	-I$(srcdir) \
	-DPACKAGE_DATA_DIR=\""$(datadir)/lxpanel2"\" \
	-DPACKAGE_LIB_DIR=\""$(libdir)/lxpanel2"\" \
	-DPACKAGE_UI_DIR=\""$(datadir)/lxpanel2/ui"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	--include config.h \
	$(NULL)
# FIXME: --include config.h is not a cross-compiler solution and is gcc-only.

# The main program -----------------------------------------------------

bin_PROGRAMS = lxpanel2

lxpanel2_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg gdk-3.0 \
    --pkg gio-2.0 \
    --pkg gio-unix-2.0 \
    --pkg gmodule-2.0 \
    --pkg posix \
	--pkg libwnck-3.0 \
	--pkg x11 \
	--pkg menu-cache \
	--pkg na-tray \
	--pkg config \
	--pkg gtop-2.0 \
	--vapidir vapi \
	--vapidir lib \
	--vapi lxpanel2.vapi \
	--header lxpanel2.h \
	--thread \
	--disable-warnings \
	$(NULL)

CORE_SOURCES = \
	lib/lxpanel-applet.vapi \
	lxpanel2.vala \
	panel.vala \
	preferences.vala \
	add-applet.vala \
	xutils.vala \
	$(NULL)

# NaTray code from gnome-panel, for systray
NATRAY_SOURCES = \
	applets/na-tray/na-tray.c \
	applets/na-tray/na-tray-child.c \
	applets/na-tray/na-tray-manager.c \
	applets/na-tray/fixedtip.c \
	applets/na-tray/na-marshal.c \
	$(NULL)

BUILTIN_APPLETS_SOURCES = \
	applets/app-menu-applet.vala \
	applets/blank-applet.vala \
	applets/clock-applet.vala \
	applets/launchbar-applet.vala \
	applets/logout-applet.vala \
	applets/netstatus-applet.vala \
	applets/pager-applet.vala \
	applets/show-desktop-applet.vala \
	applets/wnck-task-list-applet.vala \
	$(NATRAY_SOURCES) \
	applets/systray-applet.vala \
	applets/places-applet.vala \
	applets/mounts-applet.vala \
	$(NULL)

lxpanel2_SOURCES = \
	$(CORE_SOURCES) \
	$(BUILTIN_APPLETS_SOURCES) \
	gtk-run.c \
	$(NULL)

# GObject marshallers
applets/na-tray/na-marshal.h: applets/na-tray/na-marshal.list
	glib-genmarshal --header --prefix=_na_marshal $^ > $@.tmp && mv $@.tmp $@

applets/na-tray/na-marshal.c: applets/na-tray/na-marshal.list
	glib-genmarshal --body --prefix=_na_marshal $^ > $@.tmp && mv $@.tmp $@

# Workarounds to force the build
BUILT_SOURCES= \
	applets/na-tray/na-marshal.c \
	applets/na-tray/na-marshal.h \
	$(NULL)

CLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)

lxpanel2_CFLAGS = \
	-Ilib \
    -Iegg \
    -Iapplets/na-tray \
	$(GTK_CFLAGS) \
	$(GIO_CFLAGS) \
	$(WNCK_CFLAGS) \
	$(GTOP_CFLAGS) \
	$(MENU_CACHE_CFLAGS) \
	$(X11_CFLAGS) \
	$(LIBFM_CFLAGS) \
	-Werror-implicit-function-declaration \
	$(ADDITIONAL_FLAGS) \
	$(NULL)

lxpanel2_LDADD = \
	lib/liblxpanel-applet.la \
	$(GTK_LIBS) \
	$(GIO_LIBS) \
	$(WNCK_LIBS) \
	$(GTOP_LIBS) \
	$(MENU_CACHE_LIBS) \
	$(X11_LIBS) \
	$(LIBFM_LIBS) \
	$(INTLLIBS) \
	$(NULL)

lxpanel2_LDFLAGS = \
	$(NULL)

EXTRA_DIST = \
	$(NULL)
