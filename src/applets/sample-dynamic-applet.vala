//      sample-dynamic-applet.vala
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

public class SampleDynamicApplet : Gtk.Box, Applet {
	public SampleDynamicApplet(Panel panel) {
		this.panel = panel;
		var label = new Gtk.Label("Test");
		label.set_attributes(panel.get_text_attrs());
		label.show();
		add(label);
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	public static void register(ref Applet.Info info) {
		info.type_name = "sample";
		info.name= _("sample");
		info.description= _("sample for dynamic applets");
		info.author= _("Lxpanel");

		info.create_applet=(panel) => {
			debug("creator called");
			var applet = new SampleDynamicApplet(panel);
			debug("creator returned");
			return applet;
		};
		applet_info = info;
		debug("the module is registered");
	}

	public static unowned Applet.Info? applet_info;
	weak Panel panel;
}

}

// called by lxpanel when loading the module
[ModuleInit]
public bool load(GLib.TypeModule module, ref Lxpanel.Applet.Info info) {
	// FIXME: ABI compatibility check here
	Lxpanel.SampleDynamicApplet.register(ref info);
	debug("the module is loaded");
	return true;
}

// called by lxpanel before unloading the module
public void unload() {
}
