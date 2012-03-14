//      systray-applet.vala
//      
//      Copyright 2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

public class SysTrayApplet : Na.Tray, Applet {
	public SysTrayApplet(Panel panel) {
		// NaTray does not have a public constructor
		Object( // set construct properties
			screen: panel.get_screen(),
			orientation: panel.get_orientation());
		base.set_icon_size(panel.get_icon_size());
		set_padding(1);
	}

	public new void set_icon_size(int size) {
		base.set_icon_size(size);
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	public static void register() {
		applet_info.type_name = "systray";
		applet_info.name= _("System Tray");
		applet_info.description= _("System Tray");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new SysTrayApplet(panel);
			return applet;
		};
		Applet.register(ref applet_info);
	}
	public static Applet.Info applet_info;
}

}
