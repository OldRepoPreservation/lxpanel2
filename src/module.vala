namespace Lxpanel {

public class AppletModule : TypeModule {

	delegate Type LoadFunc(TypeModule module);
	delegate void UnloadFunc();

	public AppletModule(string name, string file) {
		this.name = name;
		this.file = file;
        // GTypeModule cannot be freed, so let's add a reference for it.
        // See: http://www.lanedo.com/~mitch/module-system-talk-guadec-2006/Module-System-Talk-Guadec-2006.pdf
        all_modules.prepend(this);
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
				print("module %s opened\n", file);
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

    public Type get_type_id() {
        if(type_id == 0) { // never registered
            load(); // really load the *.so module
        }
        return type_id;
    }

	string? name;
	string? file;
	Module? module;
    Type type_id;
    static SList<AppletModule> all_modules;
}

}
