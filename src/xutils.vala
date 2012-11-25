//      xutils.vala
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

namespace Lxpanel {

// ask the window manager to reserve the specified space for our panel window.
void reserve_screen_space(Gdk.Window window, Gtk.PositionType position, Gdk.Rectangle? rect) {
    // reserve space for the panel
    // See: http://standards.freedesktop.org/wm-spec/1.3/ar01s05.html#NETWMSTRUTPARTIAL
    Gdk.Atom _NET_WM_STRUT_PARTIAL = Gdk.Atom.intern_static_string("_NET_WM_STRUT_PARTIAL");
    if(rect != null) {
        // _NET_WM_STRUT_PARTIAL data format (CARDINAL[12]/32):
        // left, right, top, bottom,
        // left_start_y, left_end_y,
        // right_start_y, right_end_y,
        // top_start_x, top_end_x,
        // bottom_start_x, bottom_end_x

        ulong strut_data[12] = {0};

        switch(position) {
        case Gtk.PositionType.TOP:
        case Gtk.PositionType.BOTTOM:
            strut_data[position] = rect.height;
            strut_data[4 + position * 2] = rect.x;
            strut_data[4 + position * 2 + 1] = rect.x + rect.width - 1;
            // -1 is needed here. otherwise, some window managers will
            // also reserve the space for the adjacent monitor.
            // openbox is one of these window managers
            break;
        case Gtk.PositionType.LEFT:
        case Gtk.PositionType.RIGHT:
            strut_data[position] = rect.width;
            strut_data[4 + position * 2] = rect.y;
            strut_data[4 + position * 2 + 1] = rect.y + rect.height - 1;
            // -1 is needed here. otherwise, some window managers will
            // also reserve the space for the adjacent monitor.
            break;
        }

        Gdk.property_change(window, _NET_WM_STRUT_PARTIAL,
            Gdk.Atom.intern_static_string("CARDINAL"), 32,
            Gdk.PropMode.REPLACE, (uchar[])strut_data);
    }
    else { // remove it
        Gdk.property_delete(window, _NET_WM_STRUT_PARTIAL);
    }
}

}
