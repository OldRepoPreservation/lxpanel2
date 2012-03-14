
namespace Lxpanel {

public class LaunchButton : Button {
	
	public enum Type {
		NONE,
		APP,
		CUSTOM,
		COMMAND
	}

	public LaunchButton(LaunchButton.Type type) {
		this.type = type;
	}

	public LaunchButton.Type get_button_type() {
		return type;
	}

	public void set_desktop_id(string id) {
		desktop_id = id;
		app = new GLib.DesktopAppInfo(id);
		set_gicon(app.get_icon(), 20);
		set_tooltip_text(app.get_display_name());
	}

	public unowned string get_desktop_id() {
		return desktop_id;
	}

	public void set_command_exec(string exec) {
		command_exec = exec;
	}

	public unowned string get_command_exec() {
		return command_exec;
	}
	
	public void set_terminal(bool terminal) {
		this.terminal = terminal;
	}
	
	public bool get_terminal() {
		return terminal;
	}

	protected override void clicked() {
		// launch the button
		if(app != null) {
			app.launch(null, null);
		}
		else if(command_exec != null) {
			// flags = NEEDS_TERMINAL;
			app = GLib.AppInfo.create_from_commandline(command_exec, command_exec, 0);
			app.launch(null, null);
			app = null;
		}
	}

	private string desktop_id;
	private string command_exec;
	private bool terminal;
	private GLib.AppInfo? app;
	private LaunchButton.Type type;
}


public class LaunchbarApplet : Gtk.Box, Applet {

	public LaunchbarApplet() {
	}

	construct {
		set("orientation", Gtk.Orientation.HORIZONTAL, null);
	}

	public override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
	}

	private bool load_button(GMarkupDom.Node config_node) {
		LaunchButton? btn = null;
		var type = config_node.get_attribute("type");
		if(type == "app") { // application button
			btn = new LaunchButton(LaunchButton.Type.APP);
			foreach(unowned GMarkupDom.Node child in config_node.children) {
				if(child.name == "desktop_id") {
					btn.set_desktop_id(child.val);
				}
				else // error!!
					return false;
			}
		}
		else if(type == "custom") { // custom command button
			btn = new LaunchButton(LaunchButton.Type.CUSTOM);
			foreach(unowned GMarkupDom.Node child in config_node.children) {
				debug("%s", child.name);
				if(child.name == "command") {
					btn.set_command_exec(child.val);
				}
				else if(child.name == "icon") {
					var icon = new GLib.ThemedIcon(child.val);
					btn.set_gicon(icon, 24);
				}
				else if(child.name == "terminal") {
					btn.set_terminal(bool.parse(child.val));
				}
				else if(child.name == "label") {
					btn.set_label(child.val);
					set_tooltip_text(child.val);
				}
				else // error!!
					return false;
			}
		}
		else if(type == "command") {
			btn = new LaunchButton(LaunchButton.Type.COMMAND);
			foreach(unowned GMarkupDom.Node child in config_node.children) {
			}
		}
		// btn.set_label(@"$i");
		if(btn != null)
			pack_start(btn, false);
		return true;
	}

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "button") {
				load_button(child);
			}
		}
		show_all();
		return true;
	}
	
	public void save_config(GMarkupDom.Node config_node) {
		foreach(weak Gtk.Widget child in get_children()) {
			var btn = (LaunchButton)child;
			unowned GMarkupDom.Node btn_node;
			LaunchButton.Type type = btn.get_button_type();
			btn_node = config_node.new_child("button", null, 
							{"type"},
							{enum_to_nick<LaunchButton.Type>(type)});
			switch(type) {
			case LaunchButton.Type.APP:
				btn_node.new_child("desktop_id", btn.get_desktop_id());
				break;
			case LaunchButton.Type.CUSTOM:
				btn_node.new_child("command", btn.get_command_exec());
				btn_node.new_child("icon", btn.get_gicon().to_string());
				btn_node.new_child("label", btn.get_label());
				btn_node.new_child("terminal", btn.get_terminal().to_string());
				break;
			case LaunchButton.Type.COMMAND:
				break;
			}
		}
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	public static void register() {
		applet_info.type_name = "launchbar";
		applet_info.name= _("Launch bar");
		applet_info.description= _("Launch bar");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new LaunchbarApplet();
			return applet;
		};
		Applet.register(ref applet_info);
	}

	public static Applet.Info applet_info;
}

}
