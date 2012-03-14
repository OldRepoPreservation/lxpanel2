# Author: Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
# Copyright (C) 2011
# License: MIT

install (
    DIRECTORY ui
    DESTINATION "${CMAKE_INSTALL_DATADIR}/lxpanel2"
)

install (
#    FILES config.xml
    DIRECTORY default
#    DESTINATION "${CMAKE_INSTALL_SYSCONFDIR}/xdg/lxpanel2"
    DESTINATION "/etc/xdg/lxpanel2"
)

# merge the translations in po files with desktop.in using intltool
#intltool_desktop_entry (
#    gtk_cmake_test.desktop.in
#    ${CMAKE_SOURCE_DIR}/po
#)
