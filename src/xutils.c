//      xutils.c
//      
//      Copyright 2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
//      
//      This program is free software; you can redistribute it and/or modify
//      it under the terms of the GNU General Public License as published by
//      the Free Software Foundation; either version 2 of the License, or
//      (at your option) any later version.
//      
//      This program is distributed in the hope that it will be useful,
//      but WITHOUT ANY WARRANTY; without even the implied warranty of
//      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//      GNU General Public License for more details.
//      
//      You should have received a copy of the GNU General Public License
//      along with this program; if not, write to the Free Software
//      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
//      MA 02110-1301, USA.
//      
//      

#include <gtk/gtk.h>
#include <gdk/gdk.h>

// We implement this in plain C to workaround a bug of vala.
// in the gdk-3.0.vapi of Vala, Gdk.property_change() is broken.
// It use the byte counts as the value of n_elements parameters, which is incorrect.

// ask the window manager to reserve the specified space for our panel window.
void reserve_screen_space(GdkWindow* window, GtkPositionType position, GdkRectangle* rect) {
    // reserve space for the panel
    // See: http://standards.freedesktop.org/wm-spec/1.3/ar01s05.html#NETWMSTRUTPARTIAL
    GdkAtom _NET_WM_STRUT_PARTIAL = gdk_atom_intern_static_string("_NET_WM_STRUT_PARTIAL");
    if(rect != NULL) {
        // _NET_WM_STRUT_PARTIAL data format (CARDINAL[12]/32):
        // left, right, top, bottom,
        // left_start_y, left_end_y,
        // right_start_y, right_end_y,
        // top_start_x, top_end_x,
        // bottom_start_x, bottom_end_x

        gulong strut_data[12] = {0};
        switch(position) {
        case GTK_POS_TOP:
        case GTK_POS_BOTTOM:
            // g_print("pos: %d, %d,%d,%d,%d\n", (int)position, rect->x, rect->y, rect->width, rect->height);
            strut_data[position] = rect->height;
            strut_data[4 + position * 2] = rect->x;
            strut_data[4 + position * 2 + 1] = rect->x + rect->width - 1;
            // -1 is needed here. otherwise, some window managers will
            // also reserve the space for the adjacent monitor.
            // openbox is one of these window managers
            break;
        case GTK_POS_LEFT:
        case GTK_POS_RIGHT:
            strut_data[position] = rect->width;
            strut_data[4 + position * 2] = rect->y;
            strut_data[4 + position * 2 + 1] = rect->y + rect->height - 1;
            // -1 is needed here. otherwise, some window managers will
            // also reserve the space for the adjacent monitor.
            break;
        }
        gdk_property_change(window, _NET_WM_STRUT_PARTIAL,
            gdk_atom_intern_static_string("CARDINAL"), 32,
            GDK_PROP_MODE_REPLACE, (const char*)strut_data, G_N_ELEMENTS(strut_data));
    }
    else { // remove it
        gdk_property_delete(window, _NET_WM_STRUT_PARTIAL);
    }
}
