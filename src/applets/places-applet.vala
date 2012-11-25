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

public class PlacesApplet : Applet {

	construct {
        drawer = new Drawer();
        drawer.show();
        pack_start(drawer, false, true, 0);
	}

    protected override void set_icon_size(int size) {
        base.set_icon_size(size);
		drawer.set_gicon(new ThemedIcon("user-home"), size);
    }

	public override bool load_config(GMarkupDom.Node config_node) {
        base.load_config(config_node);
		foreach(unowned GMarkupDom.Node child in config_node.children) {
		}
		return true;
	}

	public override void save_config(GMarkupDom.Node config_node) {
        base.save_config(config_node);
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(PlacesApplet);
		applet_info.type_name = "places";
		applet_info.name= _("Places");
		applet_info.description= _("Places");
        return applet_info;
	}

	Drawer? drawer;
}

}
