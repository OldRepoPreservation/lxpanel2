NULL=

AM_CPPFLAGS = \
	-I$(srcdir) \
	-I../../ \
	-DPACKAGE_DATA_DIR=\""$(datadir)/lxpanel2"\" \
	-DPACKAGE_LIB_DIR=\""$(libdir)/lxpanel2"\" \
	-DPACKAGE_UI_DIR=\""$(datadir)/lxpanel2/ui"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	--include config.h \
	$(NULL)
# FIXME: --include config.h is not a cross-compiler solution and is gcc-only.

module_LTLIBRARIES = battery.la
moduledir = $(libdir)/lxpanel2/applets

VALAFLAGS = \
	--pkg lxpanel2 \
	--vapidir ../../vapi \
	--vapidir ../../ \
	--thread \
	--disable-warnings \
	$(NULL)

battery_la_SOURCES = \
	battery-applet.vala \
	$(NULL)

LXPANEL2_CFLAGS = \
	$(GTK_CFLAGS) \
	$(GIO_CFLAGS) \
	$(X11_CFLAGS) \
	$(NULL)

battery_la_CFLAGS = \
	-shared \
	-fPIC \
	$(LXPANEL2_CFLAGS) \
	-Werror-implicit-function-declaration \
	$(ADDITIONAL_FLAGS) \
	$(NULL)

battery_la_LIBADD = \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

battery_la_LDFLAGS = \
	-module \
	-no-undefined \
	-avoid-version \
	$(LXPANEL_MODULE_FLAGS) \
	$(NULL)
