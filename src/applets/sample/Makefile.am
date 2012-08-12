NULL=

AM_CPPFLAGS = \
	-I$(srcdir) \
	-I../../ \
	-DPACKAGE_DATA_DIR=\""$(datadir)/lxpanel2"\" \
	-DPACKAGE_LIB_DIR=\""$(libdir)/lxpanel2"\" \
	-DPACKAGE_UI_DIR=\""$(datadir)/lxpanel2/ui"\" \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	--include config.h \
	$(NULL)
# FIXME: --include config.h is not a cross-compiler solution and is gcc-only.

# A sample dynamically loadable applet module demonstrating how to
# make a applet module for lxpanel
module_LTLIBRARIES = sample.la
moduledir = $(libdir)/lxpanel2/applets

VALAFLAGS = \
	--pkg lxpanel2 \
	--vapidir ../../vapi \
	--vapidir ../../ \
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
	$(LXPANEL2_CFLAGS) \
	-Werror-implicit-function-declaration \
	$(ADDITIONAL_FLAGS) \
	$(NULL)

sample_la_LIBADD = \
	$(GTK_LIBS) \
	$(INTLLIBS) \
	$(NULL)

sample_la_LDFLAGS = \
	-module \
	-no-undefined \
	-avoid-version \
	$(LXPANEL_MODULE_FLAGS) \
	$(NULL)
