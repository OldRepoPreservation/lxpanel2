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

	construct {
		set_tooltip_text(_("Logout"));
		show_all();
	}
    
    protected void set_icon_size(int size) {
		set_gicon(new ThemedIcon("system-log-out"), size);
    }

	protected override void clicked() {
		unowned string? command = Panel.get_logout_command();
		if(command != null)
			Process.spawn_command_line_async(command);
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(LogoutApplet);
		applet_info.type_name = "logout";
		applet_info.name= _("Logout Button");
		applet_info.description= _("Logout Button");
        return (owned)applet_info;
	}
}

}
