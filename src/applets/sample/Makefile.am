NULL=

AM_CPPFLAGS = \
	-I$(srcdir) \
	-I../../ \
	-I../../lib \
	-DPACKAGE_DATA_DIR=\""$(datadir)/lxpanel2"\" \
	-DPACKAGE_LIB_DIR=\""$(libdir)/lxpanel2"\" \
	-DPACKAGE_UI_DIR=\""$(datadir)/lxpanel2/ui"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	--include config.h \
	$(NULL)
# FIXME: --include config.h is not a cross-compiler solution and is gcc-only.

# A sample dynamically loadable applet module demonstrating how to
# make a applet module for lxpanel
module_LTLIBRARIES = sample.la
moduledir = $(libdir)/lxpanel2/applets

VALAFLAGS = \
	--pkg lxpanel-applet \
	--vapidir ../../vapi \
	--vapidir ../../lib \
	--thread \
	--disable-warnings \
	$(NULL)

sample_la_SOURCES = \
	sample-dynamic-applet.vala \
	$(NULL)

LXPANEL2_CFLAGS = \
    -Iegg \
    -Iapplets/na-tray \
	$(GTK_CFLAGS) \
	$(GIO_CFLAGS) \
	$(WNCK_CFLAGS) \
	$(GTOP_CFLAGS) \
	$(MENU_CACHE_CFLAGS) \
	$(X11_CFLAGS) \
	$(NULL)

sample_la_CFLAGS = \
	-shared \
	-fPIC \
	$(LXPANEL2_CFLAGS) \
	-Werror-implicit-function-declaration \
	$(ADDITIONAL_FLAGS) \
	$(NULL)

sample_la_LIBADD = \
	../../lib/liblxpanel-applet.la \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

sample_la_LDFLAGS = \
	-module \
	-no-undefined \
	-avoid-version \
	$(LXPANEL_MODULE_FLAGS) \
	$(NULL)
