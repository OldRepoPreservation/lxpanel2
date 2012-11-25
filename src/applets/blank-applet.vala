//      blank-applet.vala
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

public class BlankApplet : Applet {

	construct {
	}

	public override bool load_config(GMarkupDom.Node config_node) {
        base.load_config(config_node);
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "size") {
				size = int.parse(child.val);
			}
			else if(child.name == "expand") {
				set_expand(bool.parse(child.val));
			}
		}
		return true;
	}

	public override void save_config(GMarkupDom.Node config_node) {
        base.save_config(config_node);
		if(size > 0)
			config_node.new_child("size", size.to_string());
        config_node.new_child("expand", get_expand().to_string());
	}
	
	protected override void get_preferred_width(out int min, out int natral) {
		if(size > 0 && orientation == Gtk.Orientation.HORIZONTAL)
			min = natral = size;
		else
			base.get_preferred_width(out min, out natral);
	}

	protected override void get_preferred_height(out int min, out int natral) {
		if(size > 0 && orientation == Gtk.Orientation.VERTICAL)
			min = natral = size;
		else
			base.get_preferred_height(out min, out natral);
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(BlankApplet);
		applet_info.type_name = "blank";
		applet_info.name= _("Blank");
		applet_info.description= _("Blank space");
		return (owned)applet_info;
	}
	int size;
}

}
