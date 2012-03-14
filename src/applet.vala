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

namespace Lxpanel {

private HashTable<unowned string, Applet.Info*> applet_types;
private List<AppletModule> modules;

public interface Applet : Gtk.Widget {

	[CCode (has_target = false)]
	public delegate Applet CreateFunc(Panel panel);

	public struct Info {
		public int version;
		public unowned string type_name;
		public unowned string name;
		public unowned string description;
		public unowned string author;
		public unowned string copyright;
		public bool expandable;
		// function used to create new instances of the applet
		public CreateFunc create_applet;
		public AppletModule? module; // used by dynamic applets
	}

	public virtual bool get_expand() {
		return false;
	}
	public virtual void set_expand(bool expand) {
	}

	public abstract unowned Info? get_info();

	public static Applet? new_from_type(Panel panel, string type_name) {
		Info* info = applet_types.lookup(type_name);
		if(info != null) {
			CreateFunc func = info->create_applet;
			if(func != null)
				return func(panel);
		}
		return null;
	}

	public virtual bool load_config(GMarkupDom.Node config_node) {
		return true;
	}
	
	public virtual void save_config(GMarkupDom.Node config_node) {
	}

	public virtual void set_icon_size(int size) {
	}

	public virtual void set_position(Gtk.PositionType pos) {
	}

	public static void register(ref Info info) {
		applet_types.insert(info.type_name, &info);
	}

	public static void unregister(ref Info info) {
		applet_types.remove(info.type_name);
	}

	public List<Info?> get_all_types() {
		register_modules();
		return null;
	}

	private static void register_module(string name, string file) {
		// make sure that it's not registered yet
		if(applet_types.lookup(name) == null) {
			var module = new AppletModule(name, file);
			modules.prepend(module);
			module.use();
			Info* info = module.get_info();
			applet_types.insert(info->name, info);
		}
	}

	private static void register_modules_in_dir(string dirpath) {
		try {
			var dir = Dir.open(dirpath);
			for(;;) { // find all *.so files in applets dir
				var name = dir.read_name();
				if(name == null)
					break;
				var path = Path.build_filename(dirpath, name, null);
				if(name.has_suffix(".so") && FileUtils.test(path, FileTest.IS_REGULAR)) {
					// a module is found, register it
					var type_name = name[0:-3];
					register_module(type_name, path);
				}
			}
		}
		catch(Error err) {
		}
	}

	private static void register_modules() {
		// we need to detect new dynamic applet modules here
		// load from user applet modules first
		string dirpath = Path.build_filename(Config.PACKAGE_LIB_DIR, "applets", null);
		register_modules_in_dir(dirpath);

		// load from system applet modules
		dirpath = Path.build_filename(Environment.get_user_config_dir(), "lxpanel2/applets", null);
		register_modules_in_dir(dirpath);
	}

	public static void register_all() {
		if(applet_types == null)
			applet_types = new HashTable<unowned string, Info*>(str_hash, str_equal);

		// register all built-in applets
		AppMenuApplet.register();
		BlankApplet.register();
		BatteryApplet.register();
		ClockApplet.register();
		LaunchbarApplet.register();
		LogoutApplet.register();
		NetstatusApplet.register();
		PagerApplet.register();
		PlacesApplet.register();
		ShowDesktopApplet.register();
		TaskListApplet.register();
		SysTrayApplet.register();
		
		// we do not register dynamic applets in modules here
		// for performance reasons.
		// we will enumerate all available modules when needed.
		register_modules();
	}
}


}
