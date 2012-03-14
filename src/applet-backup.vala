//      applet.vala
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

namespace LxPanel {

public struct AppletInfo {
	unowned string type_name;
	unowned string name;
	unowned string description;
	unowned string author;
	unowned string copyright;
	bool expandable;
}

private HashTable<string, Type> applet_types;

public interface Applet : Gtk.Widget {

	public virtual bool get_expand() {
		return false;
	}
	public virtual void set_expand(bool expand) {
	}

	public abstract unowned AppletInfo get_info();

	public static Applet? new_from_type(string type_name) {
		Type type = applet_types.lookup(type_name);
		if(type != 0) {
			return (Applet)Object.new(type);
		}
		return null;
	}

	public virtual bool init_with_config(GMarkupDom.Node config_node) {
		return true;
	}

	public static void register_all() {
		if(applet_types == null)
			applet_types = new HashTable<string, Type>(str_hash, str_equal);
		applet_types.insert("appmenu", typeof(AppMenuApplet));
		applet_types.insert("blank", typeof(BlankApplet));
		applet_types.insert("launchbar", typeof(LaunchbarApplet));
		applet_types.insert("showdesktop", typeof(ShowDesktopApplet));
		applet_types.insert("pager", typeof(PagerApplet));
		applet_types.insert("tasklist", typeof(TaskListApplet));
		applet_types.insert("logout", typeof(LogoutApplet));
		applet_types.insert("clock", typeof(ClockApplet));
		applet_types.insert("battery", typeof(BatteryApplet));
		applet_types.insert("netstatus", typeof(NetstatusApplet));
	}

}


}
