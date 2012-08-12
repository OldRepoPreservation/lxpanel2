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

public class Panel : Gtk.Window, Gtk.Orientable {

	public enum BackgroundMode {
		SYSTEM,
		WALLPAPER,
		IMAGE
	}

	public Panel() {
		_orientation = Gtk.Orientation.HORIZONTAL;
		position = Gtk.PositionType.BOTTOM;
		box = new Gtk.Box(_orientation, 0);
		box.show();
		add(box);
		order = 0;
		size = 26;
		expand = false;

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
	}

	~Panel() {
	}

	protected override void dispose() {
	}
	
	protected override void get_preferred_height(out int min, out int natural) {
		if(_orientation == Gtk.Orientation.VERTICAL) {
			min = 32;
			if(expand == true) {
				natural = get_screen().get_height();
			}
			else
				base.get_preferred_width(out min, out natural);
		}
		else {
			min = natural = size;
		}
	}
	
	protected override void get_preferred_width(out int min, out int natural) {
		if(_orientation == Gtk.Orientation.HORIZONTAL) {
			min = 32;
			if(expand == true) {
				min = natural = get_screen().get_width();
			}
			else
				base.get_preferred_width(out min, out natural);
		}
		else {
			min = natural = size;
		}
	}
	
	protected override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
		update_geometry();
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
				box.pack_start(applet, applet.get_expand(), true);
                applet.set_panel(this);
				applet.show();
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
			else if(child.name == "orientation") {
				//orientation = (Gtk.Orientation)int.parse(child.val);
				orientation = enum_nick_parse<Gtk.Orientation>(child.val);
			}
			else if(child.name == "position") {
				// position = (Gtk.PositionType)int.parse(child.val);
				position = enum_nick_parse<Gtk.PositionType>(child.val);
			}
			else if(child.name == "reserve_space") {
				reserve_space = bool.parse(child.val);
			}
			else if(child.name == "auto_hide") {
				auto_hide = bool.parse(child.val);
			}
			else if(child.name == "expand") {
				expand = bool.parse(child.val);
			}
			else if(child.name == "icon_size") {
				icon_size = int.parse(child.val);
			}
			else if(child.name == "size") {
				size = int.parse(child.val);
			}
			else if(child.name == "text_color") {
				text_color = (owned)child.val;
				if(text_color != null) {
					// create Pango.AttrList used for text display if needed
					if(text_attrs == null)
						text_attrs = new Pango.AttrList();
					Gdk.Color color;
					if(Gdk.Color.parse(text_color, out color)) {
						debug("color: %s", color.to_string());
						text_attrs.insert(Pango.attr_foreground_new(color.red, color.green, color.blue));
					}
				}
			}
			else if(child.name == "font") {
				font_desc = (owned)child.val;
				if(font_desc != null) {
					// create Pango.AttrList used for text display if needed
					if(text_attrs == null)
						text_attrs = new Pango.AttrList();
					var font = Pango.FontDescription.from_string(font_desc);
					// text_attrs.insert(Pango.attr_font_desc_new(font));
					text_attrs.insert(pango_attr_font_desc_new(font));
				}
			}
		}
		return true;
	}

	public bool save_panel(GMarkupDom.Node node) {
		node.new_child("orientation", enum_to_nick<Gtk.Orientation>(_orientation));
		node.new_child("position", enum_to_nick<Gtk.PositionType>(position));
		node.new_child("reserve_space", reserve_space.to_string());
		node.new_child("auto_hide", auto_hide.to_string());
		node.new_child("expand", expand.to_string());
		node.new_child("icon_size", icon_size.to_string());
		node.new_child("size", size.to_string());
		unowned GMarkupDom.Node applets = node.new_child("applets");
		foreach(unowned Applet applet in get_applets()) {
			unowned AppletInfo info = applet.get_info();
			unowned GMarkupDom.Node applet_node;
			applet_node = applets.new_child("applet", null, {"type"}, {info.type_name});
			applet.save_config(applet_node);
		}
		return true;
	}

	public void add_applet(Applet applet) {
		box.pack_start(applet, applet.expand);
	}

	public void insert_applet(Applet applet, int index) {
		box.pack_start(applet);
		box.reorder_child(applet, index);
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

	public void update_geometry() {
		var w = get_allocated_width();
		var h = get_allocated_height();
		var screen = get_screen();
		var sw = screen.get_width();
		var sh = screen.get_height();
		int x = 0, y = 0;

		int struct_index = 0;
		ulong reserved_size = 0;
		ulong struct_start = 0, struct_end = 0;

		switch(position) {
		case Gtk.PositionType.LEFT:
			x = 0;
			y = 0;
			struct_index = 0;
			reserved_size = w;
			struct_start = 0;
			struct_end = sh;
			break;
		case Gtk.PositionType.RIGHT:
			x = sw - w;
			y = 0;
			struct_index = 1;
			reserved_size = w;
			struct_start = 0;
			struct_end = sh;
			break;
		case Gtk.PositionType.TOP:
			y = 0;
			x = (sw - w) / 2;
			struct_index = 2;
			reserved_size = h;
			struct_start = 0;
			struct_end = sw;
			break;
		case Gtk.PositionType.BOTTOM:
			y = sh - h;
			x = (sw - w) / 2;
			struct_index = 3;
			reserved_size = h;
			struct_start = 0;
			struct_end = sw;
			break;
		}

		// FIXME: handles Panel.order here to support multiple panels
		//        on the same side of the screen.

		move(x, y);

		if(get_realized()) {
			// reserve space for the panel
			// See: http://standards.freedesktop.org/wm-spec/1.3/ar01s05.html#NETWMSTRUTPARTIAL
			Gdk.Atom _NET_WM_STRUT_PARTIAL = Gdk.Atom.intern_static_string("_NET_WM_STRUT_PARTIAL");
			if(reserve_space == true) {
				ulong struct_data[12] = {0};
				struct_data[struct_index] = reserved_size;
				struct_data[4 + struct_index * 2] = struct_start;
				struct_data[4 + struct_index * 2 + 1] = struct_end;

				Gdk.property_change(get_window(), _NET_WM_STRUT_PARTIAL,
					Gdk.Atom.intern_static_string("CARDINAL"), 32,
					Gdk.PropMode.REPLACE, (uchar[])struct_data);
			}
			else {
				Gdk.property_delete(get_window(), _NET_WM_STRUT_PARTIAL);
			}
		}
	}

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
				box.set_orientation(value);
			}
		}
	}

    public Gtk.PositionType get_position() {
        return position;
    }
    
    public void set_position(Gtk.PositionType position) {
        this.position = position;
        // TODO: call set_position() on all applets
        // reposition the panel
    }

    private static void load_theme() {
/*
        var provider = new Gtk.CssProvider();
        string css = """
            LxpanelPanel {
            background-color: #000000;
            color: #ffffff;
            background-image: url('/usr/share/lxpanel/images/background.png');
            }

            #tasklist-button {
                background-color: red;
                color: #ffffff;
            }
        """;
        provider.load_from_data(css, -1);
        var screen = Gdk.Screen.get_default();
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
*/
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
load_theme();
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
			foreach(unowned GMarkupDom.Node child in doc.root.children) {
				if(child.name == "panel") {
					var panel = new Panel();
					all_panels.append(panel);
					// stdout.printf("load panel\n");
					panel.load_panel(child);
					panel.show();
				}
				else if(child.name == "global") {
					// global settings apply to all panels
					load_global(child);
				}
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

	public unowned string? get_text_color() {
		return text_color;
	}

	public unowned string? get_font_desc() {
		return font_desc;
	}

	public unowned Pango.AttrList? get_text_attrs() {
		return text_attrs;
	}

	public static unowned string? get_file_manager() {
		return file_manager;
	}

	public static unowned string? get_logout_command() {
		return logout_command;
	}

	private string? id; // id of the panel
	private Gtk.Orientation _orientation; // orientation of the panel
	private Gtk.PositionType position; // left, top, right, bottom
	private int order; // order in panels of the same position
	private string? monitor_name; // monitor to show the panel
	private string? text_color; // text color
	private string? font_desc; // font used for text display
	private Pango.AttrList? text_attrs; // pango attribute used to draw text (generated from text_color & font_desc), can be null
	private bool expand; // expand to fill screen size
	private bool expand_across_monitors; // expand across all monitors
	private bool auto_hide; // automatically hide the panel
	private bool reserve_space; // set partial struct
	private int icon_size; // size of icons
	private int size; // size of the panel
	private Gtk.Box box; // top box used to group applets
	private static string? file_manager; // command used to launch file manager
	private static string? logout_command; // command used to logout desktop session
    private static string? theme_name; // name of the theme used
	public static List<Panel> all_panels;
}

}
