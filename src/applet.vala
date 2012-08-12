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

private HashTable<unowned string, AppletInfo> applet_types;
private List<AppletModule> modules;
private Quark applet_info_quark_id;

[Compact]
public class AppletInfo {
    public int abi_version;
    public Type type_id;
    public string type_name;
    public string? name;
    public string? version;
    public string? description;
    public string[] authors;
    public string? copyright;
    public bool expandable;
    public unowned AppletModule? module; // used by dynamic applets

    public Applet? create_new() {
        Applet applet = null;
        print("type_id: %d\n", (int)type_id);
        if(type_id != 0)
            applet = (Applet)Object.new(type_id);
        return applet;
    }

    public void load_deatils() {
        if(name != null)
            return;
        // load from applet definition file
        string base_name = @"lxpanel2/applets/$type_name.desktop";
        var keyfile = new KeyFile();
        try {
            keyfile.load_from_data_dirs(base_name, null, 0);
            name = keyfile.get_locale_string("Applet", "Name");
            version = keyfile.get_locale_string("Applet", "Version");
            description = keyfile.get_locale_string("Applet", "Description");
            authors = keyfile.get_locale_string_list("Applet", "Authors");
            version = keyfile.get_locale_string("Applet", "Copyright");
        }
        catch(Error err) {
        }
    }
}


public interface Applet : Gtk.Widget {

	public virtual bool get_expand() {
		return false;
	}

	public virtual void set_expand(bool expand) {
	}

    public virtual void set_panel(Panel panel) {
        set_panel_orientation(panel.orientation);
        set_panel_position(panel.get_position());
        set_icon_size(panel.get_icon_size());
    }

    public virtual void set_panel_orientation(Gtk.Orientation orientation) {
    }

	public virtual void set_panel_position(Gtk.PositionType pos) {
	}

	public virtual void set_icon_size(int size) {
	}

    public virtual unowned AppletInfo get_info() {
        return get_qdata<AppletInfo>(applet_info_quark_id);
    }

	public static Applet? new_from_type_name(string type_name) {
		unowned AppletInfo info = applet_types.lookup(type_name);
        if(info == null) {
            // try to load a dynamic module
            var module = AppletModule.from_name(type_name);
            if(module != null) {
                // build AppletInfo from the module
                var dynamic_info = module.build_applet_info();
                if(dynamic_info != null) {
                    info = dynamic_info;
                    applet_types.insert(type_name, (owned)dynamic_info);
                }
            }
        }
		if(info != null) {
            print("found applet: %s\n", info.type_name);
            var applet = info.create_new();
            print("applet created: %p\n", (void*)applet);
            if(applet != null) {
                applet.set_qdata_full(applet_info_quark_id, (void*)info, null);
                return applet;
            }
		}
		return null;
	}

	public virtual bool load_config(GMarkupDom.Node config_node) {
		return true;
	}
	
	public virtual void save_config(GMarkupDom.Node config_node) {
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
					if(applet_types.lookup(type_name) == null) { // it's not yet added
                        var module = new AppletModule(type_name, path);
                        var info = module.build_applet_info();
                        applet_types.insert(type_name, (owned)info);
                    }
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

    // register built-in applets
	private static void register_builtin() {
		// register all built-in applets
        AppletInfo info = null;
        info = AppMenuApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = BlankApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = BatteryApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = ClockApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = LaunchbarApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = LogoutApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = NetstatusApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = PagerApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = PlacesApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = ShowDesktopApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = WnckTaskListApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = SysTrayApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);
    }

	public static void init() {
        applet_types = new HashTable<unowned string, AppletInfo>(str_hash, str_equal);
        applet_info_quark_id = Quark.from_string("applet-info");
        register_builtin();
		// we do not register dynamic applets in modules here
		// for performance reasons.
		// we will enumerate all available modules when needed.
		// register_modules();
	}
}

}
