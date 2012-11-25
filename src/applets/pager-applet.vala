//      pager.vala
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

public class PagerApplet : Applet, Gtk.Orientable {

	construct {
        pager = new Wnck.Pager();
        pager.show();
        pack_start(pager, false, true, 0);
		n_rows = 1;
		pager.set_n_rows(1);
		pager.set_shadow_type(Gtk.ShadowType.NONE);
	}

    protected override void set_panel_orientation(Gtk.Orientation orient) {
        base.set_panel_orientation(orient);
        orientation = orient;
    }

    protected override void set_icon_size(int size) {
        // FIXME: is this correct?
        base.set_icon_size(size);
		set_size_request(size, size);
    }

	public override void get_preferred_height(out int min_h, out int natral_h) {
		if(orientation == Gtk.Orientation.HORIZONTAL) {
			min_h = 1;
			natral_h = get_icon_size();
		}
		else {
			base.get_preferred_width(out min_h, out natral_h);
		}
		debug("get_preferred_height: %d, %d", min_h, natral_h);
	}

	public override void get_preferred_width(out int min_w, out int natral_w) {
		if(orientation == Gtk.Orientation.VERTICAL) {
			min_w = 1;
			natral_w = get_icon_size();
		}
		else {
			base.get_preferred_width(out min_w, out natral_w);
		}
		debug("get_preferred_width: %d, %d", min_w, natral_w);
	}

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
				pager.set_orientation(value);
			}
		}
	}

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "rows") {
				n_rows = int.parse(child.val);
				pager.set_n_rows(n_rows);
			}
		}
		return true;
	}
	
	public void save_config(GMarkupDom.Node config_node) {
		if(n_rows > 0)
			config_node.new_child("rows", n_rows.to_string());
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(PagerApplet);
		applet_info.type_name = "pager";
		applet_info.name= _("Pager");
		applet_info.description= _("Pager");
        return applet_info;
	}

	Gtk.Orientation _orientation;
	int n_rows;
    int icon_size;
    Wnck.Pager? pager;
}

}
