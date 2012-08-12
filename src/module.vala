namespace Lxpanel {

public class AppletModule : TypeModule {

	delegate Type LoadFunc(TypeModule module);
	delegate void UnloadFunc();

	public AppletModule(string name, string file) {
		this.name = name;
		this.file = file;
	}

    public static AppletModule? from_name(string name) {
        string base_name = @"$name.so";
        // find in user-specific dir
        string file_path = Path.build_filename(Environment.get_user_config_dir(), "lxpanel2/applets", base_name, null);
        if(!FileUtils.test(file_path, FileTest.IS_REGULAR)) { // not usable
            // find in system-wide dir instead
            file_path = Path.build_filename(Config.PACKAGE_LIB_DIR, "applets", base_name, null);
            if(!FileUtils.test(file_path, FileTest.IS_REGULAR)) { // not usable
                return null;
            }
        }
        return new AppletModule(name, file_path);
    }

	public unowned string? get_name() {
		return name;
	}

	public unowned string? get_filename() {
		return file;
	}

    public bool is_loaded() {
        return module != null;
    }

	public override bool load() {
		if(file != null) {
			module = Module.open(file, ModuleFlags.BIND_LAZY);
			if(module != null) {
				debug("module %s opened", file);
				void* pfunc;
				if(module.symbol("load", out pfunc)) {
					LoadFunc load = (LoadFunc)pfunc;
                    type_id = load(this);
					if(type_id != 0) {
						// successfully loaded
                        return true;
					}
					else {
						// failed, unload the module?
					}
				}
			}
		}
		return false;
	}

	public override void unload() {
		if(module != null) {
			void* pfunc;
			if(module.symbol("unload", out pfunc)) {
				((UnloadFunc)pfunc)();
			}
            type_id = 0;
			module = null;
		}
	}

    public AppletInfo build_applet_info() {
        var info = new AppletInfo();
        if(type_id == 0)
            load();
        info.type_id = type_id;
        info.type_name = this.name;
        info.module = this;
        return (owned)info;
    }

	string? name;
	string? file;
	Module? module;
    Type type_id;
}

}
