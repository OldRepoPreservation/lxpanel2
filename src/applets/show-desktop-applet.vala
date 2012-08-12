//      show-desktop-applet.vala
//      
//      Copyright 2011 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

public class ShowDesktopApplet : Button, Applet {

	construct {
		set_tooltip_text(_("Show Desktop"));
	}

    protected void set_icon_size(int size) {
		set_gicon(new ThemedIcon("user-desktop"), size);
    }

	protected override void clicked() {
		var n = get_screen().get_number();
		var screen = Wnck.Screen.get(n);
		if(screen != null) {
			bool show = screen.get_showing_desktop();
			screen.toggle_showing_desktop(!show);
		}
	}

	public override Gtk.SizeRequestMode get_request_mode() {
		return Gtk.SizeRequestMode.CONSTANT_SIZE;
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(ShowDesktopApplet);
		applet_info.type_name = "showdesktop";
		applet_info.name= _("Show Desktop");
		applet_info.description= _("Show Desktop");
        return (owned)applet_info;
	}

}

}
