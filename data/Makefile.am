NULL=

SUBDIRS= \
	ui \
	$(NULL)

defaultdir=$(sysconfdir)/lxpanel2/default
default_DATA= \
	default/config.xml \
	$(NULL)

appletsdir=$(datadir)/lxpanel2/applets
applets_in_files = \
	applets/sample.desktop.in \
	$(NULL)
applets_DATA = $(applets_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST= \
	$(default_DATA) \
	$(applets_DATA) \
	$(NULL)
