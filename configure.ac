#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([lxpanel2], [0.1.0], [http://lxde.org/])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AC_CONFIG_HEADERS([config.h])

# Support silent build rules. Disable by either passing --disable-silent-rules
# to configure or passing V=1 to make
AM_SILENT_RULES([yes])

# Checks for programs.
AC_PROG_CC
AM_PROG_VALAC([0.16])

AC_PROG_SED # For fixing broken vapi files

#Initialize libtool
LT_PREREQ([2.2])
LT_INIT

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

# intltool
IT_PROG_INTLTOOL([0.40.0])

PKG_CHECK_MODULES(XLIB, "x11")
AC_SUBST(XLIB_CFLAGS)
AC_SUBST(XLIB_LIBS)

gtk_modules="gtk+-3.0"
PKG_CHECK_MODULES(GTK, [$gtk_modules])
AC_SUBST(GTK_CFLAGS)
AC_SUBST(GTK_LIBS)

wnck_modules="libwnck-3.0"
PKG_CHECK_MODULES(WNCK, [$wnck_modules])
AC_SUBST(WNCK_CFLAGS)
AC_SUBST(WNCK_LIBS)

gtop_modules="libgtop-2.0"
PKG_CHECK_MODULES(GTOP, [$gtop_modules])
AC_SUBST(GTOP_CFLAGS)
AC_SUBST(GTOP_LIBS)

gio_modules="gthread-2.0 gio-unix-2.0 glib-2.0 >= 2.18.0"
PKG_CHECK_MODULES(GIO, [$gio_modules])
AC_SUBST(GIO_CFLAGS)
AC_SUBST(GIO_LIBS)

menu_modules="libmenu-cache >= 0.3.2"
PKG_CHECK_MODULES(MENU_CACHE, [$menu_modules])
AC_SUBST(MENU_CACHE_CFLAGS)
AC_SUBST(MENU_CACHE_LIBS)

libfm_modules="libfm >= 1.0 libfm-gtk >= 1.0"
PKG_CHECK_MODULES(LIBFM, [$libfm_modules])
AC_SUBST(LIBFM_CFLAGS)
AC_SUBST(LIBFM_LIBS)



###########################
# Indicator Info
###########################
AC_ARG_ENABLE([indicator_support],
    AS_HELP_STRING([--enable-indicator-support],
               [enable plugin loading (default: disable)]),
               indicator_support=$enableval, indicator_support="no")
AM_CONDITIONAL(ENABLE_INDICATOR_SUPPORT, test x"$indicator_support" = x"yes")

if test "$indicator_support" != "no"; then
	INDICATOR_REQUIRED_VERSION=0.3.0
	INDICATOR_PKG_NAME=indicator-0.4

	PKG_CHECK_MODULES(APPLET, $INDICATOR_PKG_NAME >= $INDICATOR_REQUIRED_VERSION)
	AC_SUBST(APPLET_CFLAGS)

	if test "x$with_localinstall" = "xyes"; then
		INDICATORDIR="${libdir}/indicators/2/"
		INDICATORICONSDIR="${datadir}/indicator-applet/icons/"
	else
		INDICATORDIR=`$PKG_CONFIG --variable=indicatordir $INDICATOR_PKG_NAME`
		INDICATORICONSDIR=`$PKG_CONFIG --variable=iconsdir $INDICATOR_PKG_NAME`
fi
	AC_SUBST(INDICATORDIR)
	AC_SUBST(INDICATORICONSDIR)
fi

# debug support
AC_ARG_ENABLE(debug,
	[AC_HELP_STRING([--enable-debug],
		[build libfm with debug support @<:@default=no@:>@])],
	[enable_debug="${enableval}"],
	[enable_debug=no]
)
if test "$enable_debug" = "yes"; then
    # turn on debug and disable optimization
    CPPFLAGS="$CPPFLAGS -DG_ENABLE_DEBUG -O0 -g"
else
    # turn off glib debug checks
    CPPFLAGS="$CPPFLAGS -DG_DISABLE_ASSERT -DG_DISABLE_CHECKS -DG_DISABLE_CAST_CHECKS"
fi

# additional debug flags
AC_ARG_ENABLE(more_warnings,
       [AC_HELP_STRING([--enable-more-warnings],
               [Add more warnings @<:@default=no@:>@])],
       [enable_more_warnings="${enableval}"],
       [enable_more_warnings=no]
)
if test x"$enable_more_warnings" = x"yes"; then
  ADDITIONAL_FLAGS="-Wall -Werror=all -Werror=format -Werror=implicit-function-declaration -Werror=implicit-int -Werror=missing-braces -Werror=parentheses -Werror=return-type -Werror=strict-aliasing -Werror=switch -Wuninitialized -Werror=unused-label -Werror=unused-value -Wextra -Wno-missing-field-initializers -Wno-unused-parameter -Werror=missing-declarations -Wredundant-decls -Wmissing-noreturn -Wpointer-arith -Wcast-align -Wwrite-strings -Werror=inline -Werror=format-nonliteral -Wformat-nonliteral -Werror=format-security -Wformat-security -Winit-self -Werror=missing-include-dirs -Werror=undef -Werror=aggregate-return -Wmissing-format-attribute -Werror=nested-externs -fno-strict-aliasing -fmessage-length=0 -Wp,-D_FORTIFY_SOURCE=2 -DG_DISABLE_DEPRECATED -DG_DISABLE_SINGLE_INCLUDES -DGDK_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_DEPRECATED -DGDK_PIXBUF_DISABLE_SINGLE_INCLUDES -DGTK_DISABLE_DEPRECATED -DGTK_DISABLE_SINGLE_INCLUDES"
fi
AC_SUBST(ADDITIONAL_FLAGS)


# Generate po/LINGUAS on the fly rather than relying on translators
# to maintain it manually. This also overcome the problem that Transifex
# cannot add a language to po/LINGUAS if a new po file is submitted.
rm -f $srcdir/po/LINGUAS
for po_file in `ls $srcdir/po/*.po | sort`;
do
    lang=`echo "$po_file" | sed "s|.*/po/\(.*\)\.po|\1|g"`
    echo $lang >> $srcdir/po/LINGUAS
done

GETTEXT_PACKAGE=lxpanel2
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Gettext package.])

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/lib/Makefile
    src/applets/battery/Makefile
    src/applets/sample/Makefile
    data/Makefile
    data/ui/Makefile
    data/ui/about.ui
    po/Makefile.in
])

AC_OUTPUT

if test x"$sysconfdir" != x'/etc'; then
    echo
    echo
    echo 'Error: sysconfdir is not /etc.'
    echo 'Please consider passing --sysconfdir=/etc to configure.';
    echo 'Otherwise default config files will be installed to wrong place.'
    echo
    echo
else
    echo
    echo lxpanel2........................: Version $VERSION
    echo
    echo Enable debug....................: "$enable_debug"
    echo Prefix..........................: $prefix
    echo
    echo The binary will be installed in $prefix/bin
    echo
    echo http://lxde.org/
    echo
    echo "Ready to make template. Type 'make' to continue."
    echo
fi
