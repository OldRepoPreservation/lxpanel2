//      logout-applet.vala
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

class LogoutApplet : Button, Applet {

	public LogoutApplet(Panel panel) { // FIXME: avoid this kind of weird gobject constructor
		this.panel = panel;
		set_tooltip_text(_("Logout"));
		set_gicon(new ThemedIcon("system-log-out"), panel.get_icon_size());
		show_all();
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	protected override void clicked() {
		unowned string? command = panel.get_logout_command();
		if(command != null)
			Process.spawn_command_line_async(command);
	}

	public static void register() {
		applet_info.type_name = "logout";
		applet_info.name= _("Logout Button");
		applet_info.description= _("Logout Button");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new LogoutApplet(panel);
			return applet;
		};
		Applet.register(ref applet_info);
	}
	public static Applet.Info applet_info;
	weak Panel panel;
}

}
