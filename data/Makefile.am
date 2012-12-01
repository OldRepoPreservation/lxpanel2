NULL=

SUBDIRS= \
	ui \
	applet-data \
	$(NULL)

defaultconfigdir=$(sysconfdir)/xdg/lxpanel2/default
defaultconfig_DATA= \
	default/config.xml \
	$(NULL)

appletsdir=$(datadir)/lxpanel2/applets
applets_in_files = \
	applets/battery.desktop.in \
	$(NULL)
applets_DATA = $(applets_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST= \
	$(defaultconfig_DATA) \
	$(applets_DATA) \
	$(NULL)
