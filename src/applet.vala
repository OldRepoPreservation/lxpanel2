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

// Base class for all applets
public class Applet : Gtk.Box {

    construct {
    }

    public virtual bool get_expand() {
        // get if the applet is expandable.
        // by default this returns false.
        return expand;
    }

    public virtual void set_expand(bool expand) {
        // set the applet expandable.
        this.expand = expand;
    }

    public virtual void set_panel_orientation(Gtk.Orientation orientation) {
        // called by the panel when the orientation changes
        // We don't use Orientable interface + "orientation" property here
        // because it's possible that the panel and the applet want different
        // orientations. So we use a separate "panel_orientation".
        panel_orientation = orientation;
    }

    public virtual Gtk.Orientation get_panel_orientation() {
        // get the orientation of the panel containing the applet.
        return panel_orientation;
    }

    public virtual void set_panel_position(Gtk.PositionType pos) {
        // called by the panel when the position of panel changes
        panel_position = pos;
    }

    public virtual Gtk.PositionType get_panel_position() {
        // get position of the panel
        return panel_position;
    }

    public virtual void set_icon_size(int size) {
        // called by the panel when icon size changes
        icon_size = size;
    }

    public virtual int get_icon_size() {
        // get icon size specified for this panel.
        return icon_size;
    }

    public virtual bool load_config(GMarkupDom.Node config_node) {
        // called by the panel to load configurations
        return true;
    }

    public virtual void save_config(GMarkupDom.Node config_node) {
        // called by the panel to write configurations
    }

    public virtual void edit_config(Gtk.Window? parent_window) {
        // called by the panel configuration UI to launch a preference dialog.
    }

    public virtual void customize_context_menu(Gtk.UIManager* ui) {
        // called by the panel to setup the context menu prior to show it.
    }

    public void show_context_menu() {
        // emit a signal to ask the panel to show a context menu for the applet
        var act_grp = new Gtk.ActionGroup("LXPanel");
        act_grp.add_actions(popup_menu_actions, this);
        var ui = new Gtk.UIManager();
        ui.insert_action_group(act_grp, 0);
        ui.add_ui_from_string(popup_menu_xml, -1);
        customize_context_menu(ui); // give the derived class a chance to customize the menu
        var menu = (Gtk.Menu)ui.get_widget("/popup");
        menu.popup(null, null, null, 3, Gtk.get_current_event_time());
        // menu.attach_to_widget(applet, null);
        menu.selection_done.connect(() => {menu.destroy();});

    }

    // mouse button pressed
    protected override bool button_press_event(Gdk.EventButton evt) {
        // Normally, we'll never receive this signal because the Applet class
        // is derived from GtkBox, a type of widget having no window (GTK_NO_WINDOW).
        // So, X11 never sends the mouse events to us. The button_press_event is
        // actually received by the Panel and then forwarded to us.
        if(base.button_press_event != null)
            base.button_press_event(evt);
        if(evt.button == 3) { // right click
            show_context_menu();
        }
        return true;
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
                    applet_types.insert(dynamic_info.type_name, (owned)dynamic_info);
                }
            }
        }
        if(info != null) {
            var applet = info.create_new();
            if(applet != null) {
                applet.set_qdata_full(applet_info_quark_id, (void*)info, null);
                return applet;
            }
            else {
                stderr.printf("applet %s cannot be loaded.\n", type_name);
            }
        }
        return null;
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

        info = MountsApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = NetstatusApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = PagerApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = PlacesApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = ShowDesktopApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = SysTrayApplet.build_info();
        applet_types.insert(info.type_name, (owned)info);

        info = WnckTaskListApplet.build_info();
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

    private void on_add_new_applet(Gtk.Action action) {
        var panel = get_toplevel();
        if(panel != null) {
            // here we utilize action signal rather than
            // calling a method of Panel, so we don't need to be linked 
            // with the main program lxpanel.
            GLib.Signal.emit_by_name(panel, "add_applet", this);
        }
    }

    private void on_remove_applet(Gtk.Action action) {
        destroy();
        // TODO: if the applet is in a dynamic module, and
        // we released the last references of the applet class,
        // unload the dynamic module to save memory.
    }

    private void on_config_applet(Gtk.Action action) {
        edit_config(null);
    }

    private void on_panel_pref(Gtk.Action action) {
        var panel = get_toplevel();
        if(panel != null) {
            // here we utilize action signal rather than
            // calling a method of Panel, so we don't need to be linked 
            // with the main program lxpanel.
            GLib.Signal.emit_by_name(panel, "preferences");
        }
    }

    bool expand = false;
    int icon_size = 24;
    Gtk.Orientation panel_orientation = Gtk.Orientation.HORIZONTAL;
    Gtk.PositionType panel_position = Gtk.PositionType.BOTTOM;

    private const string popup_menu_xml ="""
    <popup>
        <placeholder name='first'/>
        <separator/>
        <menuitem action='add'/>
        <menuitem action='remove'/>
        <menuitem action='prop'/>
        <separator/>
        <menuitem action='pref'/>
        <placeholder name='last'/>
    </popup>""";
    const Gtk.ActionEntry[] popup_menu_actions = {
        {"add", Gtk.Stock.ADD, N_("_Add New Applet"), null, N_("Add new applet to the panel"), on_add_new_applet},
        {"remove", Gtk.Stock.REMOVE, null, null, N_("Remove the applet to the panel"), on_remove_applet},
        {"prop", Gtk.Stock.PROPERTIES, null, null, N_("Properties of the applet to the panel"), on_config_applet},
        {"pref", Gtk.Stock.PREFERENCES, N_("Panel Preferences"), null, null, on_panel_pref}
    };
}

}
