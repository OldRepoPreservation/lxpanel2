namespace Lxpanel {
    
// need to increase the number everytime the Applet API changes.
public const uint APPLET_ABI_VERSION = 1;

public class AppletModule : Object {

	delegate Type LoadFunc(uint abi_version);
	delegate void UnloadFunc();

	public AppletModule(string name, string file) {
		this.name = name;
		this.file = file;
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

	public bool load() {
        if(module == null) {
            if(file != null) {
                module = Module.open(file, ModuleFlags.BIND_LAZY);
                if(module != null) {
                    print("module %s opened\n", file);
                    void* pfunc;
                    if(module.symbol("load", out pfunc)) {
                        LoadFunc load = (LoadFunc)pfunc;
                        type_id = load(APPLET_ABI_VERSION);
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
		}
		return true;
	}

	public void unload() {
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
	Module? module = null;
    Type type_id;
}

}
