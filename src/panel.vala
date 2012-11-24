/*
namespace Pango {
	[CCode (cheader_filename = "pango/pango.h")]
	public static Pango.Attribute attr_font_desc_new(Pango.FontDescription desc);
}
*/

// FIXME: temporary hack! vala does not have this API in pango vapi.
// we should report this bug to vala devs. :-(
extern Pango.Attribute pango_attr_font_desc_new(Pango.FontDescription desc);

namespace Lxpanel {

enum SizeMode {
    AUTO,
    PERCENT,
    PIXEL
}

public class Panel : Gtk.Window, Gtk.Orientable {

	public Panel() {
		box = new Gtk.Box(_orientation, 0);
		box.show();
		add(box);

        rect.x = rect.y = rect.width = rect.height = 0;

		set_border_width(1);
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

		var sc = get_style_context();
		sc.add_class("toolbar");

		screen_changed(null);
	}

	~Panel() {
	}

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

    // when the window is really created.
    protected override void realize() {
        base.realize();
    }

    // when the size or position of the panel window is changed.
    protected override bool configure_event(Gdk.EventConfigure event) {
        var ret = base.configure_event(event);
        if(rect.x != event.x || rect.y != event.y || rect.width != event.width || rect.height != event.height) {
            rect.x = event.x;
            rect.y = event.y;
            rect.width = event.width;
            rect.height = event.height;
            // when receiving a "configure-event" signal, the position and
            // size of the window is changed, so it's the right time to update
            // the space we ask the window manager to reserve for us.
            if(reserve_space) {
                // this takes some X roundtrip and is very expansive.
                // do it only when the new size is really different.
                reserve_screen_space(get_window(), position, rect);
            }
        }
        return ret;
    }

    // when size of the panel allocated by gtk+ is changed.
	protected override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
        Gdk.Rectangle arect = (Gdk.Rectangle)allocation;
        // we only reposition the panel if its size is really changed
        if(arect.width != rect.width || arect.height != rect.height) {
            if(length_mode == SizeMode.AUTO)
                update_geometry(); // reposition the panel
        }
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
                set_position(position);
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
			else if(child.name == "text_color") {
				text_color = (owned)child.val;
				if(text_color != null) {
				}
			}
			else if(child.name == "font") {
				font_desc = (owned)child.val;
				if(font_desc != null) {
				}
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

	public void insert_applet(Applet applet, int index = -1) {
		box.pack_start(applet, applet.get_expand(), true);
		if(index >= 0)
			box.reorder_child(applet, index);
		applet.set_panel(this);
		applet.show();
	}

	public void reorder_applet(Applet applet, int index) {
		box.reorder_child(applet, index);
	}

	public void remove_applet(Applet applet) {
		box.remove(applet);
	}

	public unowned Gtk.Box get_box() {
		return box;
	}

	public unowned Wnck.Screen get_wnck_screen() {
		int n = get_screen().get_number();
		return Wnck.Screen.get(n);
	}

    private void set_monitor(int monitor) {
        if(this.monitor != monitor) {
            this.monitor = monitor;
            update_geometry();
        }
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
        print("%s: %d, %d, %d, %d, %d, %d\n", id, x, y, width, height, length, length_mode);
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

	public Gtk.PositionType get_position() {
		return position;
	}
	
	public void set_position(Gtk.PositionType position) {
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

	public unowned string? get_id() {
		return id;
	}

	public int get_icon_size() {
		return icon_size;
	}

	public void set_icon_size(int size) {
		foreach(weak Applet applet in get_applets()) {
			applet.set_icon_size(size);
		}
	}

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
    private Gdk.Rectangle rect; // rectangle caching the on-screen position & size of the panel.

	// global settings
	private static string? file_manager; // command used to launch file manager
	private static string? logout_command; // command used to logout desktop session
	private static string? theme_name; // name of the theme used
	private static Gtk.CssProvider? theme_css_provider; // css provider of the selected theme
	public static List<Panel> all_panels;

    // may be deprecated
	private string? text_color; // text color
	private string? font_desc; // font used for text display

}

}
