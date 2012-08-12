/*
 * wnck-task-list-applet.vala
 * 
 * Copyright (C) 2012 Hong Jen Yee <pcman.tw@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

namespace Lxpanel {

public class WnckTaskListApplet : Wnck.Tasklist, Applet {

    construct {
        set_button_relief(Gtk.ReliefStyle.NONE);
    }
	public bool get_expand() {
		return expand;
	}

	public void set_expand(bool expand) {
		this.expand = expand;
	}

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "expand") {
				expand = bool.parse(child.val);
			}
		}
		return true;
	}

	public void save_config(GMarkupDom.Node config_node) {
		if(expand == true)
			config_node.new_child("expand", expand.to_string());
	}

	internal static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(WnckTaskListApplet);
		applet_info.type_name = "wncktasklist";
		applet_info.name= _("Tasklist");
		applet_info.description= _("Tasklist");
        return (owned)applet_info;
	}
	bool expand = true;
}

}

