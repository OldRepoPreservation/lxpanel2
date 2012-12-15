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

    private void on_config_dlg_response(Gtk.Dialog dlg, int response) {
        dlg.destroy();
        config_dlg = null;
    }

    private void on_expand_toggled(Gtk.ToggleButton btn) {
        set_expand(btn.get_active());
    }

    private void on_size_value_changed(Gtk.SpinButton btn) {
        
    }

    public override void edit_config(Gtk.Window? parent_window) {
        if(config_dlg == null) {
            var builder = new Gtk.Builder();
            try {
                builder.add_from_file(Config.PACKAGE_DATA_DIR + "/applet-data/blank/ui/pref.ui");
                config_dlg = (Gtk.Dialog)builder.get_object("dialog");
                var expand_btn = (Gtk.CheckButton)builder.get_object("expand_btn");
                expand_btn.set_active(get_expand());
                expand_btn.toggled.connect(on_expand_toggled);
                var size_spin = (Gtk.SpinButton)builder.get_object("size_spin");
                size_spin.set_value(size);
                size_spin.value_changed.connect(on_size_value_changed);
                config_dlg.set_transient_for(parent_window);
                config_dlg.response.connect(on_config_dlg_response);
            }
            catch(Error err) {
            }
        }
        config_dlg.present();
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
    Gtk.Dialog? config_dlg = null;
}

}
