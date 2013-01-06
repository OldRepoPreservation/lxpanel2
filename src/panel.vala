//      panel.vala
//      
//      Copyright 2011-2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

// defined in xutils.c
extern void reserve_screen_space(Gdk.Window window, Gtk.PositionType position, Gdk.Rectangle? rect);

namespace Lxpanel {

public enum SizeMode {
    AUTO,
    PERCENT,
    PIXEL
}

public class Panel : Gtk.Window, Gtk.Orientable {

	public Panel() {
        // receive mouse button press event.
        add_events(Gdk.EventMask.BUTTON_PRESS_MASK);

        // the toplevel box use to layout applets
		box = new Gtk.Box(_orientation, 0);
		box.show();
		add(box);

        old_rect.x = old_rect.y = old_rect.width = old_rect.height = 0;

		set_border_width(0); // should we use 1 and paint a 3D border instead?
		// set_app_paintable(true);
		set_decorated(false);
		set_deletable(false);
		set_keep_above(true);
		set_skip_pager_hint(true);
		set_skip_taskbar_hint(true);
		set_has_resize_grip(false);
		set_type_hint(Gdk.WindowTypeHint.DOCK);
		set_default_size(320, 26);
		set_resizable(false);
		stick();

        // make the panel looks like a toolbar.
		var sc = get_style_context();
		sc.add_class("toolbar");
		screen_changed(null);
	}

	~Panel() {
	}

    // call this action signal to add a new applet
    [Signal(action=true)]
    public virtual signal void add_applet_action(Applet? current_applet) {
        // show the "Add applet" dialog.
        int pos = get_applets().index(current_applet);
        if(pos != -1) {
            var applet = choose_new_applet(null, this);
            if(applet != null) {
                insert_applet(applet, pos);
            }
        }
    }

    // call this action signal to remove an existing applet
    [Signal(action=true)]
    public virtual signal void remove_applet_action(Applet? current_applet) {
        remove_applet(current_applet);
    }

    // call this action signal to launch the preferences dialog
    [Signal(action=true)]
    public virtual signal void preferences() {
        edit_preferences(this);
    }

    // an applet is added to the panel
    public signal void applet_added(Applet applet, int pos);

    // an applet is removed from the panel
    public signal void applet_removed(Applet applet, int pos);

    // an applet is reordered
    public signal void applet_reordered(Applet applet, int new_pos);


    // initialize multiple screen & multiple monitor support.
    private static void init_multi_monitors() {
        // setup screens
        var display = Gdk.Display.get_default();
        var n_screens = display.get_n_screens();
        for(int i = 0; i < n_screens; ++i) {
            var screen = display.get_screen(i);
            screen.monitors_changed.connect(on_monitors_changed);
        }
    }

    // terminate multiple screen & multiple monitor support.
    private static void finalize_multi_monitors() {
        // unset screens
        var display = Gdk.Display.get_default();
        var n_screens = display.get_n_screens();
        for(int i = 0; i < n_screens; ++i) {
            var screen = display.get_screen(i);
            screen.monitors_changed.disconnect(on_monitors_changed);
        }
    }

    // called when the panel is destroyed. may be called more than once.
	protected override void destroy() {
        all_panels.remove(this);
        if(all_panels == null)
            finalize_multi_monitors();
	}

    // if size or numbers of monitors change
	private static void on_monitors_changed(Gdk.Screen screen) {
        var screen_num = screen.get_number();
        // we need to update_geometry and resize all panels on this screen as appropriate
        foreach(unowned Panel panel in all_panels) {
            if(panel.screen_num == screen_num) {
                panel.update_geometry();
            }
        }
	}

	protected override void get_preferred_height(out int min, out int natural) {
		if(_orientation == Gtk.Orientation.VERTICAL) {
            switch(length_mode) {
            case SizeMode.AUTO:
				base.get_preferred_height(out min, out natural);
                break;
            case SizeMode.PIXEL:
                min = natural = length;
                break;
            case SizeMode.PERCENT:
                // we set this to 100 arbitrarily since we'll set_size_request()
                // on it according to screen size later in update_geometry()
				min = natural = 100;
                break;
			}
		}
		else {
			min = natural = thickness;
		}
	}

	protected override void get_preferred_width(out int min, out int natural) {
		if(_orientation == Gtk.Orientation.HORIZONTAL) {
            switch(length_mode) {
            case SizeMode.AUTO:
				base.get_preferred_width(out min, out natural);
                break;
            case SizeMode.PIXEL:
                min = natural = length;
                break;
            case SizeMode.PERCENT:
                // we set this to 100 arbitrarily since we'll set_size_request()
                // on it according to screen size later in update_geometry()
				min = natural = 100;
                break;
			}
		}
		else {
			min = natural = thickness;
		}
	}

    // when the window is really created by X11
    protected override void realize() {
        base.realize();
    }

    // when the size or position of the panel window is changed.
    protected override bool configure_event(Gdk.EventConfigure event) {
        var ret = base.configure_event(event);
        if(old_rect.x != event.x || old_rect.y != event.y || old_rect.width != event.width || old_rect.height != event.height) {
            old_rect.x = event.x;
            old_rect.y = event.y;
            old_rect.width = event.width;
            old_rect.height = event.height;
            // when receiving a "configure-event" signal, the position and
            // size of the window is changed, so it's the right time to update
            // the space we ask the window manager to reserve for us.
            if(reserve_space) {
                // this takes some X roundtrip and is very expansive.
                // do it only when the new size is really different.
                reserve_screen_space(get_window(), position, old_rect);
            }
        }
        return ret;
    }

    // when size of the panel allocated by gtk+ is changed.
	protected override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
        Gdk.Rectangle alloc_rect = (Gdk.Rectangle)allocation;
        // print("alloc_rect %s: %d, %d, %d, %d\n", id, alloc_rect.x, alloc_rect.y, alloc_rect.width, alloc_rect.height);
        // we only reposition the panel if its size is really changed
        if(alloc_rect.width != old_rect.width || alloc_rect.height != old_rect.height) {
            if(length_mode == SizeMode.AUTO)
                update_geometry(); // reposition the panel
        }
	}

    // mouse button pressed
    protected override bool button_press_event(Gdk.EventButton evt) {
        // Normally, the panel itself does not receive button-press-event
        // because the mouse event are received by the applet widgets on it.
        // However, if the applet widget has no window (GTK_NO_WINDOW flag set),
        // we get the mouse event here. So we try to redirect the signal for the applet.
        if(base.button_press_event != null)
            base.button_press_event(evt);

        foreach(unowned Applet applet in get_applets()) {
            Gtk.Allocation alloc;
            applet.get_allocation(out alloc);
            if(evt.x >= alloc.x && evt.y >= alloc.y
            && evt.x <= (alloc.x + alloc.width)
            && evt.y <= (alloc.y + alloc.height)) {
                // forward the event to the applet that has no window.
                // FIXME: will this cause problems? coordinates might be wrong.
                applet.button_press_event(evt);
                break;
            }
        }
        return true;
    }

	protected override bool draw(Cairo.Context cr) {
		/*
		var sc = get_style_context();
		cr.save();
		if(background_pixbuf != null) {
			// paint the background with selected image
			Gdk.cairo_set_source_pixbuf(cr, background_pixbuf, 0, 0);
			var pattern = cr.get_source();
			pattern.set_extend(Cairo.Extend.REPEAT);
			cr.fill();
			cr.paint();
		}
		else {
			// paint the backgrond with gtk+ theme
			Gtk.render_background(sc, cr, 0, 0, get_allocated_width(), get_allocated_height());
			Gtk.render_frame(sc, cr, 0, 0, get_allocated_width(), get_allocated_height());
		}
		cr.restore();
		*/
		return base.draw(cr);
	}

    // load an applet from a config file node.
	private bool load_applet(GMarkupDom.Node node) {
		var applet_type = node.get_attribute("type");
		var applet = Applet.new_from_type_name(applet_type);
		// print("applet: %s, %p\n", applet_type, applet);
		if(applet != null) {
			if(applet.load_config(node)) {
				insert_applet(applet);
			}
		}
		return true;
	}

    // load the panel from a config file node
	public bool load_panel(GMarkupDom.Node node) {

		id = node.get_attribute("id");

		foreach(unowned GMarkupDom.Node child in node.children) {
			if(child.name == "applets") {
				foreach(unowned GMarkupDom.Node applet_node in child.children) {
					if(applet_node.name == "applet") {
						load_applet(applet_node);
					}
				}
			}
			else if(child.name == "position") {
				// position = (Gtk.PositionType)int.parse(child.val);
				position = enum_nick_parse<Gtk.PositionType>(child.val);
                set_position(position, true);
			}
			else if(child.name == "reserve_space") {
				reserve_space = bool.parse(child.val);
			}
			else if(child.name == "auto_hide") {
				auto_hide = bool.parse(child.val);
			}
			else if(child.name == "xscreen") {
				screen_num = int.parse(child.val);
			}
			else if(child.name == "icon_size") {
				icon_size = int.parse(child.val);
			}
			else if(child.name == "thickness") {
				thickness = int.parse(child.val);
			}
			else if(child.name == "length") {
				length = int.parse(child.val);
			}
			else if(child.name == "length_mode") {
				length_mode = enum_nick_parse<SizeMode>(child.val);
			}
            else if(child.name == "alignment") {
                alignment = double.parse(child.val);
            }
			else if(child.name == "left_margin") {
				left_margin = int.parse(child.val);
			}
			else if(child.name == "left_margin") {
				left_margin = int.parse(child.val);
			}
			else if(child.name == "top_margin") {
				top_margin = int.parse(child.val);
			}
			else if(child.name == "right_margin") {
				right_margin = int.parse(child.val);
			}
			else if(child.name == "bottom_margin") {
				bottom_margin = int.parse(child.val);
			}
            else if(child.name == "monitor") {
                set_monitor(int.parse(child.val));
            }
            else if(child.name == "span_monitors") {
                span_monitors = bool.parse(child.val);
            }
            else if(child.name == "auto_hide") {
                auto_hide = bool.parse(child.val);
            }
		}

        // Settings XScreen number is an ancient featurea and is very rarely used.
        if(screen_num >0) {
            Gdk.Display display = Gdk.Display.get_default();
            if(screen_num < display.get_n_screens())
                set_screen(display.get_screen(screen_num));
        }

		return true;
	}

    // save the panel to a config file node
	public bool save_panel(GMarkupDom.Node node) {
		node.new_child("position", enum_to_nick<Gtk.PositionType>(position));
		node.new_child("left_margin", left_margin.to_string());
		node.new_child("top_margin", top_margin.to_string());
		node.new_child("right_margin", right_margin.to_string());
		node.new_child("bottom_margin", bottom_margin.to_string());
		node.new_child("icon_size", icon_size.to_string());
		node.new_child("thickness", thickness.to_string());
		node.new_child("length", length.to_string());
		node.new_child("length_mode", enum_to_nick<SizeMode>(length_mode));
        node.new_child("alignment", alignment.to_string());
		node.new_child("reserve_space", reserve_space.to_string());
		node.new_child("auto_hide", auto_hide.to_string());
		node.new_child("monitor", monitor.to_string());
		node.new_child("xscreen", screen_num.to_string());
		node.new_child("span_monitors", span_monitors.to_string());
		node.new_child("auto_hide", auto_hide.to_string());
		unowned GMarkupDom.Node applets = node.new_child("applets");
		foreach(unowned Applet applet in get_applets()) {
			unowned AppletInfo info = applet.get_info();
			unowned GMarkupDom.Node applet_node;
			applet_node = applets.new_child("applet", null, {"type"}, {info.type_name});
			applet.save_config(applet_node);
		}
		return true;
	}

    // insert an applet to the panel at a specified index
	public void insert_applet(Applet applet, int index = -1) {
		box.pack_start(applet, applet.get_expand(), true);
		if(index >= 0)
			box.reorder_child(applet, index);

        applet.set_panel_orientation(_orientation);
        applet.set_panel_position(position);
        applet.set_icon_size(icon_size);
		applet.show();

        applet_added(applet, index); // emit a signal
	}

    // move an applet to a new position specified by index
	public void reorder_applet(Applet applet, int new_pos) {
		box.reorder_child(applet, new_pos);
        applet_reordered(applet, new_pos); // emit a signal
	}

    // remove an applet from the panel. this caused destruction
    // of the applet widget, unless it's referenced by others.
	public void remove_applet(Applet applet) {
        int pos = get_applets().index(applet);
        if(pos != -1) {
            box.remove(applet);
            applet_removed(applet, pos); // emit a signal
        }
	}

    // get the toplevel container box for all applets
	public unowned Gtk.Box get_box() {
		return box;
	}

    // resize and reposition the panel according to current monitor size.
	public void update_geometry() {
        // If length_mode is SizeMode.AUTO, the length of the panel is
        // determined by gtk so we don't touch it here. We only calculate
        // a new position for it and reposition the panel.
        // Otherwise, if the length of the panel is determined by monitor 
        // size, such as SizeMode.PERCENT, or it's set to fixed pixel size,
        // we use gtk_set_size_request() here to update its size.
		Gdk.Rectangle monitor_rect = {0};
        var screen = get_screen();
        // FIXME: how to handle the case when the specified monitor does not exist?
        if(monitor >= screen.get_n_monitors()) {
            monitor = screen.get_primary_monitor();
        }
        // get the size of the monitor we're on.
        if(span_monitors) {
            monitor_rect.width = screen.get_width();
            monitor_rect.height = screen.get_height();
            monitor_rect.x = monitor_rect.y = 0;
        }
        else
            screen.get_monitor_geometry(monitor, out monitor_rect);

        // add margins
        monitor_rect.x += left_margin;
        monitor_rect.y += top_margin;
        monitor_rect.width -= (left_margin + right_margin);
        monitor_rect.height -= (top_margin + bottom_margin);

		int x = 0, y = 0, width = 0, height = 0;
        // FIXME: supports alignment

        if(orientation == Gtk.Orientation.HORIZONTAL) {
            height = thickness;
            if(length_mode == SizeMode.PERCENT)
                width = monitor_rect.width * length / 100;
            else if(length_mode == SizeMode.PIXEL)
                width = length;
            else
                width = get_allocated_width();
            x = monitor_rect.x + (int)((monitor_rect.width - width) * alignment);
            if(position == Gtk.PositionType.BOTTOM)
                y = (monitor_rect.y + monitor_rect.height) - height;
            else
                y = monitor_rect.y;
        }
        else { // orientation == Gtk.Orientation.VERTICAL
            width = thickness;
            if(length_mode == SizeMode.PERCENT)
                height = monitor_rect.height * length / 100;
            else if(length_mode == SizeMode.PIXEL)
                height = length;
            else
                height = get_allocated_height();
            y = monitor_rect.y + (int)((monitor_rect.height - height) * alignment);
            if(position == Gtk.PositionType.RIGHT)
                x = (monitor_rect.x + monitor_rect.width) - width;
            else
                x = monitor_rect.x;
        }
        if(length_mode != SizeMode.AUTO)
            set_size_request(width, height);
		move(x, y); // reposition the panel
        // print("%s: %d, %d, %d, %d, %d, %d\n", id, x, y, width, height, length, length_mode);
	}

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
            if(_orientation != value) {
                _orientation = value;
                box.set_orientation(value);
                // call set_panel_orientation() on all applets
                foreach(weak Applet applet in get_applets()) {
                    applet.set_panel_orientation(orientation);
                }
            }
		}
	}

	private static void load_theme() {
		var screen = Gdk.Screen.get_default();
		if(theme_css_provider != null) {
			// remove the old theme
			Gtk.StyleContext.remove_provider_for_screen(screen, theme_css_provider);
		}

		if(theme_name != null) {
			var dir = locate_theme_dir(theme_name);
			if(dir != null) {
				var theme_css_file = Path.build_filename(dir, "lxpanel.css", null);
				theme_css_provider = new Gtk.CssProvider();
				theme_css_provider.load_from_path(theme_css_file);
				Gtk.StyleContext.add_provider_for_screen(screen, theme_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
			}
		}
	}

	// global settings apply to all panels
	private static bool load_global(GMarkupDom.Node node) {
		foreach(unowned GMarkupDom.Node child in node.children) {
			if(child.name == "file_manager")
				file_manager = child.val;
			else if(child.name == "logout_command")
				logout_command = child.val;
			else if(child.name == "theme")
				theme_name = child.val;
		}
		return true;
	}

	public static bool load_all_panels(string profile_name) {

		var loaded = false;
		var doc = new GMarkupDom.Doc();
		// try to load user-specific config file first
		var fpath = Path.build_filename(Environment.get_user_config_dir(), "lxpanel2", profile_name, "config.xml", null);
		if(doc.load(fpath) && doc.root != null) {
			loaded = true;
		}
		else {
			// failed, try to load system-wide config file
			foreach(unowned string dir in Environment.get_system_config_dirs()) {
				fpath = Path.build_filename(dir, "lxpanel2", profile_name, "config.xml", null);
				if(doc.load(fpath) && doc.root != null) {
					loaded = true;
					break;
				}
			}
		}

		if(loaded) { // if a config file is successfully loaded

			load_theme(); // load theme css file
            init_multi_monitors(); // setup multi-monitor support

			foreach(unowned GMarkupDom.Node child in doc.root.children) {
				if(child.name == "panel") {
					var panel = new Panel();
					all_panels.append(panel);
					// stdout.printf("load panel\n");
					panel.load_panel(child);
                    // realize the panel, so later relayout can trigger
                    // configure-event correctly. FIXME: this is a little bit hackish.
                    panel.realize();
				}
				else if(child.name == "global") {
					// global settings apply to all panels
					load_global(child);
				}
			}

            // relayout all panels
            var display = Gdk.Display.get_default();
            int n_screens = display.get_n_screens();
            for(int i = 0; i < n_screens; ++i) {
                on_monitors_changed(display.get_screen(i));
            }

            // show them after repositioning.
            foreach(unowned Panel panel in all_panels) {
                panel.show();
            }
		}
		else
			return false;
		return true;
	}

	public static bool save_all_panels(string profile_name) {
		var doc = new GMarkupDom.Doc();
		doc.root = new GMarkupDom.Node(null, "lxpanel", null, null);
		unowned GMarkupDom.Node global_node = doc.root.new_child("global", null);
		// save global config
		if(file_manager != null)
			global_node.new_child("file_manager", file_manager);
		if(logout_command != null)
			global_node.new_child("logout_command", logout_command);
		if(theme_name != null)
			global_node.new_child("theme", theme_name);

		// save panels
		foreach(weak Panel panel in all_panels) {
			unowned GMarkupDom.Node node;
			node = doc.root.new_child("panel", null, {"id"}, {panel.id});
			panel.save_panel(node);
		}

		// write the xml doc to a user-specific config file
		var dirpath = Path.build_filename(Environment.get_user_config_dir(), "lxpanel2", profile_name, null);
		if(GLib.DirUtils.create_with_parents(dirpath, 0700) == 0) {
			var fpath = Path.build_filename(dirpath, "config.xml", null);
			return doc.save(fpath);
		}

		return false;
	}

	public List<weak Applet> get_applets() {
		return (List<weak Applet>)box.get_children();
	}

    public static unowned List<weak Panel> get_all() {
        return all_panels;
    }

	public static bool is_id_unique(string id) {
		foreach(unowned Panel panel in all_panels) {
			if(panel.id == id) {
				return false;
			}
		}
		return true;
	}

	public static Panel add_panel(string id, int pos = -1) {
		if(!is_id_unique(id)) // this is not possible
			return null;
		Panel panel = new Panel();
		panel.id = id;
		all_panels.insert(panel, pos);
		panel.show();
		panel.realize();
		panel.update_geometry();
		return panel;
	}

	public static void reorder_panel(Panel panel, int new_pos) {
		panel.ref();
		all_panels.remove(panel);
		all_panels.insert(panel, new_pos);
		panel.unref();
	}

	public unowned string? get_id() {
		return id;
	}
	public void set_id(string id){
        this.id = id;
    }


	public Gtk.PositionType get_position() {
		return position;
	}
	public void set_position(Gtk.PositionType position, bool force = false) {
        if(this.position != position || force) {
            this.position = position;

            // change orientation according to position
            switch(position) {
            case Gtk.PositionType.TOP:
            case Gtk.PositionType.BOTTOM:
                orientation = Gtk.Orientation.HORIZONTAL;
                break;
            case Gtk.PositionType.LEFT:
            case Gtk.PositionType.RIGHT:
                orientation = Gtk.Orientation.VERTICAL;
                break;
            }

            // call set_panel_position() on all applets
            foreach(weak Applet applet in get_applets()) {
                applet.set_panel_position(position);
            }
            update_geometry();
        }
	}

    public int get_left_margin(){
        return left_margin;
    }
    public void set_left_margin(int left_margin){
        if(this.left_margin != left_margin) {
            this.left_margin = left_margin;
            update_geometry();
        }
    }

    public int get_top_margin(){
        return top_margin;
    }
    public void set_top_margin(int top_margin){
        if(this.top_margin != top_margin) {
            this.top_margin = top_margin;
            update_geometry();
        }
    }

    public int get_right_margin(){
        return right_margin;
    }
    public void set_right_margin(int right_margin){
        if(this.right_margin != right_margin) {
            this.right_margin = right_margin;
            update_geometry();
        }
    }

    public int get_bottom_margin(){
        return bottom_margin;
    }
    public void set_bottom_margin(int bottom_margin){
        if(this.bottom_margin != bottom_margin) {
            this.bottom_margin = bottom_margin;
            update_geometry();
        }
    }

	public bool get_span_monitors(){
        return span_monitors;
    }
	public void set_span_monitors(bool span_monitors){
        if(this.span_monitors != span_monitors) {
            this.span_monitors = span_monitors;
            update_geometry();
        }
    }

	public int get_thickness(){
        return thickness;
    }
	public void set_thickness(int thickness){
        if(this.thickness != thickness) {
            this.thickness = thickness;
            update_geometry();
        }
    }

    public int get_length(){
        return length;
    }
    public void set_length(int length){
        if(this.length != length) {
            this.length = length;
            update_geometry();
        }
    }

    public SizeMode get_length_mode(){
        return length_mode;
    }
    public void set_length_mode(SizeMode length_mode){
        if(this.length_mode != length_mode) {
            this.length_mode = length_mode;
            update_geometry();
        }
    }

    public double get_alignment(){
        return alignment;
    }
    public void set_alignment(double alignment){
        if(this.alignment != alignment) {
            this.alignment = alignment;
            update_geometry();
        }
    }

    public int get_screen_num(){
        return screen_num;
    }
    public void set_screen_num(int screen_num){
        this.screen_num = screen_num;
    }

	public int get_monitor(){
        return monitor;
    }
    public void set_monitor(int monitor) {
        if(this.monitor != monitor) {
            this.monitor = monitor;
            update_geometry();
        }
    }

	public bool get_auto_hide(){
        return auto_hide;
    }
	public void set_auto_hide(bool auto_hide){
        if(this.auto_hide != auto_hide) {
            this.auto_hide = auto_hide;
        }
    }

	public bool get_reserve_space(){
        return reserve_space;
    }
	public void set_reserve_space(bool reserve_space){
        if(this.reserve_space != reserve_space) {
            this.reserve_space = reserve_space;
            if(reserve_space) {
                reserve_screen_space(get_window(), position, old_rect);
            }
            else {
                reserve_screen_space(get_window(), position, null);
            }
        }
    }

	public int get_icon_size() {
		return icon_size;
	}
	public void set_icon_size(int size) {
        if(icon_size != size) {
            foreach(weak Applet applet in get_applets()) {
                applet.set_icon_size(size);
            }
        }
	}

    // static methods
	public static unowned string? get_file_manager() {
		return file_manager;
	}

	public static unowned string? get_logout_command() {
		return logout_command;
	}

	// panel-specific settings
	private string? id; // id of the panel
	private Gtk.Orientation _orientation = Gtk.Orientation.HORIZONTAL; // orientation of the panel
	private Gtk.PositionType position = Gtk.PositionType.BOTTOM; // left, top, right, bottom
    private int left_margin = 0; // reserved margin for left of screen
    private int top_margin = 0; // reserved margin for top of screen
    private int right_margin = 0; // reserved margin for right of screen
    private int bottom_margin = 0; // reserved margin for bottom of screen
	private bool span_monitors = false; // span across monitors
	private int thickness = 26; // size of the panel
    private int length = 100; // length of the panel
    private SizeMode length_mode = SizeMode.AUTO; // mode of length;
    private double alignment = 0.5; // alignment of the panel, 0.0 - 1.0
    private int screen_num = 0; // index of X Screen the panel belongs to (multi-screen setup is rare nowadays)
	private int monitor = 0; // index of the monitor
	private bool auto_hide = false; // automatically hide the panel
	private bool reserve_space = true; // set partial struct
	private int icon_size = 24; // size of icons

    // GUI stuff
	private Gtk.Box box; // top box used to group applets
    private Gdk.Rectangle old_rect; // rectangle caching the on-screen position & size of the panel.
    private Gtk.Dialog? pref_dlg; // preference dialog

	// global settings
	private static string? file_manager; // command used to launch file manager
	private static string? logout_command; // command used to logout desktop session
	private static string? theme_name; // name of the theme used
	private static Gtk.CssProvider? theme_css_provider; // css provider of the selected theme
	public static List<Panel> all_panels;

}

}
