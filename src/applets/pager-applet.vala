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

// FIXME: after changing an Applet from GtkBox to GtkGrid,
// sizing of the pager gets some unresolved problems...
// When orientation is horizontal, Wnck.Pager set its height to 48 by default.
// Its width is determined by get_preferred_width_for_height().
// gtk_widget_set_size_request() can no longer shrink a widget after gtk3.
// To force a widget to be smaller, we need to override its 
// get_preferred_width/height() methods and returned smaller values.

private class Pager : Wnck.Pager {

    public Pager(PagerApplet parent) {
        this.parent = parent;
    }

	public override void get_preferred_height(out int min_h, out int natral_h) {
		if(parent.orientation == Gtk.Orientation.HORIZONTAL) {
			min_h = natral_h = parent.get_icon_size();
		}
        else {
			base.get_preferred_height(out min_h, out natral_h);
        }
	}

	public override void get_preferred_width(out int min_w, out int natral_w) {
		if(parent.orientation == Gtk.Orientation.VERTICAL) {
			min_w = natral_w = parent.get_icon_size();
		}
		else {
			base.get_preferred_width(out min_w, out natral_w);
		}
	}

    private unowned PagerApplet parent;
}


public class PagerApplet : Applet, Gtk.Orientable {

	construct {
        pager = new Pager(this);
        pager.show();

		n_rows = 1;
		pager.set_n_rows(1);
		pager.set_shadow_type(Gtk.ShadowType.NONE);

		expand = false;
        pager.expand = false;
        add(pager);
	}

    protected override void set_panel_orientation(Gtk.Orientation orient) {
        base.set_panel_orientation(orient);
        orientation = orient;
    }

    protected override void set_icon_size(int size) {
        base.set_icon_size(size);
        queue_resize();
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
