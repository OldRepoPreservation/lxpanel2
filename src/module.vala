namespace Lxpanel {

public class AppletModule : TypeModule {
	
	delegate bool LoadFunc(TypeModule module, ref Applet.Info info);
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

	public override bool load() {
		if(file != null) {
			module = Module.open(file, ModuleFlags.BIND_LAZY);
			if(module != null) {
				debug("module %s opened", file);
				void* pfunc;
				if(module.symbol("load", out pfunc)) {
					LoadFunc load = (LoadFunc)pfunc;
					if(load(this, ref info)) {
						// successfully loaded
						debug("module %s loaded", file);
						return true;
					}
					else {
						// failed, unload the module
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
			module = null;
		}
	}

	public Applet.Info* get_info() {
		return &info;
	}

	string? name;
	string? file;
	Module? module;
	Applet.Info info;
}

}
