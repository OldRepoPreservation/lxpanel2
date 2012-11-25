namespace Lxpanel {

public class TaskAppButton : Button {

	public TaskAppButton(Panel panel, Wnck.Application application) {
		this.panel = panel;
		this.application = application;
		application.icon_changed.connect(on_icon_changed);
		application.name_changed.connect(on_name_changed);

		// create our own label widget
		add(new Gtk.Label(""));
		on_name_changed(application);
		on_icon_changed(application);
	}

	protected override void dispose() {
		application.icon_changed.disconnect(on_icon_changed);
		application.name_changed.disconnect(on_name_changed);
	}

	protected void on_icon_changed(Wnck.Application application) {
		var pix = application.get_icon();
		int icon_size = panel.get_icon_size();
		pix = pix.scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
		set_icon_pixbuf(pix);
	}

	protected void on_name_changed(Wnck.Application application) {
		set_tooltip_text(application.get_name());
		// set_label(win.get_name());
		weak Gtk.Label label = (Gtk.Label)get_child();
		label.set_text("[%s]".printf(application.get_name()));
	}

	protected override void clicked() {
		unowned List<weak Wnck.Window> windows = application.get_windows();
		if(windows != null) {
			var popup = new Popup();
			var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			popup.add(box);
			foreach(var window in windows) {
				var btn = new TaskButton(panel, window);
				box.add(btn);
			}
			box.show_all();
			popup.popup(get_menu_position, 1, Gtk.get_current_event_time());
		}
	}

	private weak Wnck.Application application;
	private weak Panel panel;
}


public class TaskButton : Button {

	public TaskButton(Panel panel, Wnck.Window win) {
		this.panel = panel;
		this.win = win;
		expand = true;
		win.name_changed.connect(on_name_changed);
		win.icon_changed.connect(on_icon_changed);
		win.state_changed.connect(on_state_changed);
		win.workspace_changed.connect(on_workspace_changed);
		update_icon();

		// create our own label widget
		var label = new Gtk.Label("");
		label.set_single_line_mode(true);
		label.set_alignment(0.0f, 0.5f);
		add(label);
		on_name_changed(win);
	}

	public override void dispose() {
		win.name_changed.disconnect(on_name_changed);
		win.icon_changed.disconnect(on_icon_changed);
		win.state_changed.disconnect(on_state_changed);
		win.workspace_changed.disconnect(on_workspace_changed);
		base.dispose();
	}

	public override void clicked() {
		if(win.is_active()) {
			win.minimize();
		}
		else {
			win.activate(Gtk.get_current_event_time());
		}
	}

	private void update_icon() {
		var pix = win.get_icon();
		int icon_size = panel.get_icon_size();
		pix = pix.scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
		set_icon_pixbuf(pix);
	}

	private void on_name_changed(Wnck.Window window) {
		set_tooltip_text(win.get_name());
		// set_label(win.get_name());
		weak Gtk.Label label = (Gtk.Label)get_child();
		if((win.get_state() & Wnck.WindowState.MINIMIZED) != 0) {
			label.set_text("[%s]".printf(win.get_name()));
		}
		else {
			label.set_text(win.get_name());
		}
	}

	private void on_icon_changed(Wnck.Window window) {
		update_icon();
	}

	private void on_state_changed(Wnck.Window window, Wnck.WindowState changed_mask, Wnck.WindowState new_state) {
		// update title
		if((changed_mask & Wnck.WindowState.MINIMIZED) != 0) {
			weak Gtk.Label label = (Gtk.Label)get_child();
			if((new_state & Wnck.WindowState.MINIMIZED) != 0) {
				label.set_text("[%s]".printf(win.get_name()));
			}
			else {
				label.set_text(win.get_name());
			}
		}
	}

	private void on_workspace_changed(Wnck.Window window) {
		var ws = window.get_screen().get_active_workspace();
		set_visible(win.is_on_workspace(ws));
	}

	protected override bool button_press_event(Gdk.EventButton event) {
		var ret = base.button_press_event(event);
		if(event.button == 3) { // right click
			var menu = new Wnck.ActionMenu(win);
			menu.selection_done.connect(() => {
				menu.destroy();
			});
			menu.popup(null, null, get_menu_position, 3, event.time);
		}
		return ret;
	}

	protected override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
		if(get_realized()) {
			int x, y;
			get_window().get_origin(out x, out y);
			win.set_icon_geometry(x + allocation.x, y + allocation.y, allocation.width, allocation.height);
		}
	}

	weak Wnck.Window win;
	weak Panel panel;
}


public class TaskListApplet : Applet, Gtk.Orientable {

	public TaskListApplet(Panel panel) {
		this.panel = panel;
        this.grid = new Grid();

		set_has_window(false);
		set_orientation(Gtk.Orientation.HORIZONTAL);
		set_size_request(1, 1);

		min_btn_size = 64;
		max_btn_size = 150;

		// FIXME: we determine button height by icon size regardless of
		// font size for ease of implementation. Is this acceptable?
		btn_height = panel.get_icon_size() + 2;
		show_label = true;

		hash = new HashTable<weak Wnck.Window, weak TaskButton>(direct_hash, direct_equal);
	}

	public override void dispose() {
		if(screen != null) {
			screen.application_opened.disconnect(on_application_opened);
			screen.application_closed.disconnect(on_application_closed);
			screen.class_group_opened.disconnect(on_class_group_opened);
			screen.class_group_closed.disconnect(on_class_group_closed);
			screen.window_opened.disconnect(on_window_opened);
			screen.window_closed.disconnect(on_window_closed);
			screen.active_window_changed.disconnect(on_active_window_changed);
			screen.active_workspace_changed.disconnect(on_active_workspace_changed);
			screen = null;
		}
		base.dispose();
	}

	public override void realize() {
		base.realize();
		screen = Wnck.Screen.get(get_screen().get_number());

		if(screen != null) {
			screen.application_opened.connect(on_application_opened);
			screen.application_closed.connect(on_application_closed);
			screen.class_group_opened.connect(on_class_group_opened);
			screen.class_group_closed.connect(on_class_group_closed);
			screen.window_opened.connect(on_window_opened);
			screen.window_closed.connect(on_window_closed);
			screen.active_window_changed.connect(on_active_window_changed);
			screen.active_workspace_changed.connect(on_active_workspace_changed);
			unowned List<Wnck.Window> windows = screen.get_windows();
			foreach(unowned Wnck.Window window in windows) {
				on_window_opened(screen, window);
			}
		}
	}

	private void on_application_opened(Wnck.Screen screen, Wnck.Application application) {
		if(group_windows == false)
			return;
		debug("app open: %s, %d", application.get_name(), application.get_n_windows());

		var btn = new TaskAppButton(panel, application);

		var label = (Gtk.Label)btn.get_child();
		label.set_ellipsize(Pango.EllipsizeMode.END);
		var attrs = panel.get_text_attrs();
		if(attrs != null)
			label.set_attributes(attrs);

		btn.set_show_label(show_label);
		btn.set_image_position(Gtk.PositionType.LEFT);
		if(show_label == true)
			btn.set_size_request(max_btn_size, -1);

		add(btn);

		var ws = screen.get_active_workspace();
		// hash.insert(window, btn);
		btn.set_visible(ws == null);
	}

	private void on_application_closed(Wnck.Screen screen, Wnck.Application application) {
		if(group_windows == false)
			return;
		debug("app close: %s, %d", application.get_name(), application.get_n_windows());
	}

	private void on_class_group_opened(Wnck.Screen screen, Wnck.ClassGroup group) {
		debug("class group open: %s, %d", group.get_name(), (int)group.get_windows().length());
	}

	private void on_class_group_closed(Wnck.Screen screen, Wnck.ClassGroup group) {
		debug("class group close: %s, %d", group.get_name(), (int)group.get_windows().length());
	}

	private void on_window_opened(Wnck.Screen screen, Wnck.Window window) {
		if(group_windows == true) {
			// update the app button
			return;
		}

		debug("win open: %s", window.get_name());
		if(!window.is_skip_tasklist()) {
			var btn = new TaskButton(panel, window);

			var label = (Gtk.Label)btn.get_child();
			label.set_ellipsize(Pango.EllipsizeMode.END);
			var attrs = panel.get_text_attrs();
			if(attrs != null)
				label.set_attributes(attrs);

			btn.set_show_label(show_label);
			btn.set_image_position(Gtk.PositionType.LEFT);
			if(show_label == true)
				btn.set_size_request(max_btn_size, -1);

			add(btn);

			var ws = screen.get_active_workspace();
			hash.insert(window, btn);
			btn.set_visible(ws == null || window.is_on_workspace(ws));
		}
	}

	private void on_window_closed(Wnck.Screen screen, Wnck.Window window) {
		debug("win close: %s", window.get_name());
		unowned TaskButton? btn = hash.lookup(window);
		if(btn != null) {
			btn.destroy();
			hash.remove(window);
		}
	}

	public void on_active_window_changed(Wnck.Screen screen, Wnck.Window? prev_active) {
		unowned TaskButton? btn = hash.lookup(prev_active);

		// unset selected state of the previously active window
		if(btn != null) {
			btn.unset_state_flags(Gtk.StateFlags.SELECTED);
		}

		// set selected state of the currently active window
		btn = hash.lookup(screen.get_active_window());
		if(btn != null) {
			btn.set_state_flags(Gtk.StateFlags.SELECTED, false);
		}
	}

	public void on_active_workspace_changed(Wnck.Screen screen, Wnck.Workspace? prev) {
		// show windows in current workspace and hide others
		Wnck.Workspace ws = screen.get_active_workspace();
		var it = HashTableIter<weak Wnck.Window, weak TaskButton>(hash);
		unowned Wnck.Window win;
		unowned TaskButton btn;
		while(it.next(out win, out btn)) {
			btn.set_visible(win.is_on_workspace(ws));
		}
	}

	protected override void get_preferred_width(out int min_w, out int natral_w) {
		if(show_label) {
			min_w = natral_w = 32;
		}
		else {
			base.get_preferred_width(out min_w, out natral_w);
		}
	}

	public bool get_expand() {
		return show_label;
	}

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "max_btn_size") {
				max_btn_size = int.parse(child.val);
			}
			else if(child.name == "min_btn_size") {
				min_btn_size = int.parse(child.val);
			}
			else if(child.name == "show_label") {
				show_label =  bool.parse(child.val);
			}
			else if(child.name == "group_windows") {
				group_windows =  bool.parse(child.val);
			}
			// later buttons will be created in on_window_opened()
			// and we don't have to apply these values to them here.
		}
		return true;
	}

	public void save_config(GMarkupDom.Node config_node) {
		config_node.new_child("max_btn_size", max_btn_size.to_string());
		config_node.new_child("min_btn_size", min_btn_size.to_string());
		config_node.new_child("show_label", show_label.to_string());
		config_node.new_child("group_windows", group_windows.to_string());
	}
	
	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
				set_orientation(value);
			}
		}
	}

	// Applet iface
	public static AppletInfo get_info() {
        AppletInfo applet_info = new AppletInfo();
		applet_info.type_name = "tasklist";
		applet_info.name= _("Task List");
		applet_info.description= _("Task List");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new TaskListApplet(panel);
			return applet;
		};
        return applet_info;
	}

	private int max_btn_size;
	private int min_btn_size;
	private int btn_height;
	private bool show_label;
	private bool group_windows;
	
	private Gtk.Orientation _orientation;

	private weak Wnck.Screen screen;
	private HashTable<weak Wnck.Window, weak TaskButton> hash;
	private weak Panel panel;

    private Grid grid;
}

}
