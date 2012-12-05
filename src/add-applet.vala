//      add-applet.vala
//      
//      Copyright 2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

class AppletChooserDialog : Gtk.Dialog {

    public void setup_ui(Gtk.Window? parent_win, Panel panel, Gtk.Builder builder) {
        this.panel = panel;
        panel.destroy.connect(() => {
            destroy(); // destroy the dialog if its parent panel is destroyed.
            this.panel = null;
        });

        // load the UI
        // needs to associate this object with the dialog
        if(parent_win != null)
            set_transient_for(parent_win);

        load_applets_list(builder);
    }

    public AppletInfo get_selected() {
        AppletInfo info = null;
        var tree_sel = applet_view.get_selection();
        Gtk.TreeIter iter;
        if(tree_sel.get_selected(null, out iter)) {
            applet_store.get(iter, 3, out info, -1);
        }
        return info;
    }

    private void load_applets_list(Gtk.Builder builder) {
        applet_view = (Gtk.TreeView)builder.get_object("applet_view");
        var tree_sel = applet_view.get_selection();
        var store = new Gtk.ListStore(4, typeof(GLib.Icon), typeof(string), typeof(string), typeof(AppletInfo));
        applet_view.set_model(store);
        applet_store = store;

        Gtk.TreeIter iter;
        var applet_infos = Applet.get_all_types();
        foreach(unowned AppletInfo info in applet_infos) {
            store.append(out iter);
            GLib.Icon icon = null;
            store.set(iter,
                0, icon,
                1, info.name,
                2, info.description,
                3, info,
                -1);
        }
        tree_sel.set_mode(Gtk.SelectionMode.BROWSE);
        store.get_iter_first(out iter);
        tree_sel.select_iter(iter);
    }

    unowned Panel panel;
    unowned Gtk.TreeView applet_view;
    unowned Gtk.ListStore applet_store;
}

// Let the user choose from a list of available applets, create the
// selected one, and return.
// return null if some errors happen.
public Applet choose_new_applet(Gtk.Window? parent_window, Panel panel) {
    Applet applet = null;
    Gtk.Builder builder;
    var dlg = (AppletChooserDialog)derived_widget_from_gtk_builder(
                    Config.PACKAGE_UI_DIR + "/add-applet.ui",
                    "dialog", typeof(Gtk.Dialog), typeof(AppletChooserDialog),
                    out builder);
    if(dlg != null) {
        dlg.setup_ui(parent_window, panel, builder);
        dlg.run();
        var info = dlg.get_selected();
        if(info != null) {
            applet = info.create_new();
        }
        dlg.destroy();
    }
    return applet;
}

}
