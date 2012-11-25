//      systray-applet.vala
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

public class SysTrayApplet : Applet {

	construct {
        frame = new Gtk.Frame("");
        frame.show();
        frame.set_shadow_type(Gtk.ShadowType.NONE);
        pack_start(frame, false, true, 0);
	}

    protected override void parent_set(Gtk.Widget? old_parent) {
        // base.parent_set(old_parent);
        if(tray == null) {
            tray = new Na.Tray.for_screen(get_screen(), orientation);
            tray.set_padding(1);
            tray.show();
            add(tray);
        }
    }

    protected override void set_panel_orientation(Gtk.Orientation orient) {
        base.set_panel_orientation(orient);
        orientation = orient;
    }

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
                if(tray != null)
                    tray.set_orientation(value);
			}
		}
	}

	public override void set_icon_size(int size) {
        base.set_icon_size(size);
        if(tray != null) {
            tray.set_icon_size(size);
        }
	}

    protected override void screen_changed(Gdk.Screen prev) {
        // NaTray is a per-screen object.
        // If screen is changed, though this is really really rare, we need to recreate it.
        if(tray != null) {
            tray.destroy();
            tray = null;
        }
        tray = new Na.Tray.for_screen(get_screen(), _orientation);
        tray.set_padding(1);
        tray.show();
        add(tray);
    }

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(SysTrayApplet);
		applet_info.type_name = "systray";
		applet_info.name= _("System Tray");
		applet_info.description= _("System Tray");
        return (owned)applet_info;
	}

    Na.Tray? tray;
    Gtk.Orientation _orientation;
    Gtk.Frame frame;
}

}
