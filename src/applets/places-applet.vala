//      place-applet.vala
//      
//      Copyright 2011-2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

public class PlacesApplet : Drawer, Applet {

	public PlacesApplet(Panel panel) {
		set_gicon(new ThemedIcon("user-home"), panel.get_icon_size());
	}

	public bool get_expand() {
		return expand;
	}

	public void set_expand(bool expand) {
		this.expand = expand;
	}

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
		}
		return true;
	}

	public void save_config(GMarkupDom.Node config_node) {
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	public static void register() {
		applet_info.type_name = "places";
		applet_info.name= _("Places");
		applet_info.description= _("Places");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new PlacesApplet(panel);
			return applet;
		};
		Applet.register(ref applet_info);
	}
	public static Applet.Info applet_info;

	bool expand;
}

}
