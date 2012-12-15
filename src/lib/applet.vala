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

public class AppletInfo : Object {
    public Type type_id = 0;
    public string type_name;
    public string? name;
    public string? version;
    public string? description;
    public string[] authors;
    public string? copyright;
    public bool expandable;
    public AppletModule? module; // used by dynamic applets (always null for built-in applets)

    public Applet? create_new() {
        Applet applet = null;
        if(type_id == 0) { // dynamic module is not yet loaded
            type_id = module.get_type_id();
        }
        if(type_id != 0) {
            applet = (Applet)Object.new(type_id);
            if(applet != null) {
                applet.set_info(this);
            }
        }
        return applet;
    }

    // load applet info from *.desktop file.
    public static AppletInfo? from_file(string applet_id, string info_path) {
        // check if there is an associated *.so module installed.
        var module_path = Config.PACKAGE_LIB_DIR + @"/applets/$applet_id.so";
        if(FileUtils.test(module_path, FileTest.IS_REGULAR)) {
            // load the applet module info from the desktop entry file.
            var keyfile = new KeyFile();
            try {
                keyfile.load_from_file(info_path, 0);
                var info = new AppletInfo();
                info.type_name = applet_id;
                info.name = keyfile.get_locale_string("Applet", "Name");
                info.module = new AppletModule(applet_id, module_path);
                info.description = keyfile.get_locale_string("Applet", "Description");
                try{
                    info.version = keyfile.get_locale_string("Applet", "Version");
                }catch(Error e){};
                try{
                    info.authors = keyfile.get_locale_string_list("Applet", "Authors");
                }catch(Error e){};
                try{
                    info.version = keyfile.get_locale_string("Applet", "Copyright");
                }catch(Error e){};
                return (owned)info;
            }
            catch(Error err) {
                print("load error: %s\n", err.message);
            }
        }
        return null;
    }
}

// Base class for all applets
public class Applet : Gtk.Box {

    construct {
    }

    // The following public virtual methods are aimed to be
    // overriden by derived classes to build new applets
    // -----------------------------------------------------------------

    public virtual bool get_expand() {
        // get if the applet is expandable.
        // by default this returns false.
        return expand;
    }

    public virtual void set_expand(bool expand) {
        // set the applet expandable.
        this.expand = expand;
        var parent = (Gtk.Box)get_parent();
        if(parent != null) {
            // this is a little bit dirty but works well
            parent.set_child_packing(this, expand, true, 0, Gtk.PackType.START);
        }
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

    public virtual void customize_context_menu(Gtk.UIManager ui) {
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

    // The following methods are private the the internal implementation
    // of Lxpanel.Applet
    // -----------------------------------------------------------------

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

    public unowned AppletInfo get_info() {
        return applet_info;
    }

    public void set_info(AppletInfo info) {
        applet_info = info;
    }

    public static Applet? new_from_type_name(string type_name) {
        var info = applet_types.lookup(type_name);
        if(info != null) {
            var applet = info.create_new();
            if(applet != null) {
                applet.applet_info = info;
                return applet;
            }
            else {
                stderr.printf("applet %s cannot be loaded.\n", type_name);
            }
        }
        return null;
    }
    
    public static void register_applet_info(AppletInfo info) {
        applet_types.insert(info.type_name, info);
    }

    public static void init() {
        applet_types = new HashTable<unowned string, AppletInfo>(str_hash, str_equal);
        reload_applet_types(); // find and load dynamic applets
    }

    private void on_add_new_applet(Gtk.Action action) {
        var panel = get_toplevel();
        if(panel != null) {
            // here we utilize action signal rather than
            // calling a method of Panel, so we don't need to be linked 
            // with the main program lxpanel.
            GLib.Signal.emit_by_name(panel, "add_applet_action", this);
        }
    }

    private void on_remove_applet(Gtk.Action action) {
        var panel = get_toplevel();
        if(panel != null) {
            // here we utilize action signal rather than
            // calling a method of Panel, so we don't need to be linked 
            // with the main program lxpanel.
            GLib.Signal.emit_by_name(panel, "remove_applet_action", this);
        }
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

    // reload all available types (do not need to touch built-in applets)
    public static void reload_applet_types() {
        // TODO: we may check mtimes to detect changes to prevent
        // unnecessary dir scan

        // remove invalid applets modules that no longer exists
        applet_types.foreach_remove((id, info) => {
            if(info.module != null) { // if it's a dynamic module
                // FIXME: should we check existance of *.desktop file instead?
                var module_path = info.module.get_filename();
                if(!FileUtils.test(module_path, FileTest.IS_REGULAR)) {
                    // the module *.so file no more exist, remove the AppletInfo.
                    return true;
                }
            }
            return false;
        });

        // reload dynamic modules info from dirs
        var dirpath = Config.PACKAGE_DATA_DIR + "/applets";
        try {
            var dir = Dir.open(dirpath);
            for(;;) { // find all *.desktop files in applets dir
                var name = dir.read_name();
                if(name == null || !name.has_suffix(".desktop"))
                    break;
                var path = Path.build_filename(dirpath, name, null);
                if(FileUtils.test(path, FileTest.IS_REGULAR)) {
                    // an applet module is found, register it
                    var applet_id = name[0:-8];
                    AppletInfo info = applet_types.lookup(applet_id);
                    if(info != null) {
                        // FIXME: should we reload and update applet info here?
                    }
                    else { // it's not yet added, create a new AppInfo object for it
                        info = AppletInfo.from_file(applet_id, path);
                        if(info != null) {
                            applet_types.insert(info.type_name, (owned)info);
                        }
                    }
                }
            }
        }
        catch(Error err) {
        }
    }

    // get a newly-allocated list of known Applet infos.
    public static List<unowned AppletInfo> get_all_types() {
        reload_applet_types(); // reload available applet info if needed

        // add all known applet types to a newly-allocated list
        List<unowned AppletInfo> list = null;
        applet_types.foreach((key, val) => {
            list.prepend(val);
        });
        // sort by name
        list.sort((a, b) => {
            return strcmp(a.name, b.name);
        });
        return (owned)list;
    }

    bool expand = false;
    int icon_size = 24;
    Gtk.Orientation panel_orientation = Gtk.Orientation.HORIZONTAL;
    Gtk.PositionType panel_position = Gtk.PositionType.BOTTOM;
    unowned AppletInfo applet_info = null;

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

    private static HashTable<unowned string, AppletInfo> applet_types;
    private static List<AppletModule> modules;
}

}
