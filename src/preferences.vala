//      preferences.vala
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

private Gtk.Dialog pref_dlg = null;

private void on_pref_dlg_response(Gtk.Dialog dlg, int response) {
    if(response != 0) {
        // FIXME: save config here.
        dlg.destroy();
        pref_dlg = null;
    }
}

private void setup_applet_model(Gtk.TreeStore store) {
    Gtk.TreeIter iter;
    foreach(unowned Panel panel in Panel.get_all()) {
        store.append(out iter, null);
        store.set(iter, 1, "Panel: " + panel.get_id(), 2, panel, -1);

        foreach(unowned Applet applet in panel.get_applets()) {
            Gtk.TreeIter child_iter;
            store.append(out child_iter, iter);
            unowned AppletInfo info = applet.get_info();
            store.set(child_iter, 1, info.name, 2, applet, -1);
        }
    }
}

// show the about dialog
private void on_about(Gtk.Button button) {
    var builder = new Gtk.Builder();
    try {
        builder.add_from_file(Config.PACKAGE_UI_DIR + "/about.ui");
        var dlg = (Gtk.Dialog)builder.get_object("dlg");
        dlg.set_transient_for(pref_dlg);
        dlg.response.connect((dlg, response) => {
            dlg.destroy();
        });
        dlg.run();
    }
    catch(Error err) {
    }
}

private void on_applet_view_sel_changed(Gtk.TreeSelection sel) {
    
}

private void on_add_panel(Gtk.Button btn) {
}

private void on_add_applet(Gtk.Button btn) {
}

private void on_remove(Gtk.Button btn) {
}

private void on_pref(Gtk.Button btn) {
}

private void on_move_up(Gtk.Button btn) {
}

private void on_move_down(Gtk.Button btn) {
}

// setup the preference dialog
private void setup_pref_dlg(Gtk.Builder builder) {
    
    // the view used to show applet layout
    var applet_view = (Gtk.TreeView)builder.get_object("applet_view");
    applet_view.set_level_indentation(12);
    applet_view.set_reorderable(true);
    
    // create the data model for the applet view
    var applet_store = new Gtk.TreeStore(3, typeof(GLib.Icon), typeof(string), typeof(Gtk.Widget));
    setup_applet_model(applet_store);
    applet_view.set_model(applet_store);
    applet_view.expand_all();

    var applet_view_sel = applet_view.get_selection();
    applet_view_sel.set_mode(Gtk.SelectionMode.BROWSE);
    // select the first item in the view
    Gtk.TreeIter iter;
    applet_store.get_iter_first(out iter);
    applet_view_sel.select_iter(iter);
    applet_view_sel.changed.connect(on_applet_view_sel_changed);

    // setup buttons
    var add_panel_btn = (Gtk.Button)builder.get_object("add_panel_btn");
    add_panel_btn.clicked.connect(on_add_panel);

    var add_applet_btn = (Gtk.Button)builder.get_object("add_applet_btn");
    add_applet_btn.clicked.connect(on_add_applet);

    var remove_btn = (Gtk.Button)builder.get_object("remove_btn");
    remove_btn.clicked.connect(on_remove);

    var pref_btn = (Gtk.Button)builder.get_object("pref_btn");
    pref_btn.clicked.connect(on_pref);

    var move_up_btn = (Gtk.Button)builder.get_object("move_up_btn");
    move_up_btn.clicked.connect(on_move_up);

    var move_down_btn = (Gtk.Button)builder.get_object("move_down_btn");    
    move_down_btn.clicked.connect(on_move_down);

    ((Gtk.Button)builder.get_object("about_btn")).clicked.connect(on_about);
    pref_dlg.response.connect(on_pref_dlg_response);

    applet_view.grab_focus();
}

// Launch preference dialog for all panels
public void edit_preferences() {
    if(pref_dlg == null) {
        var builder = new Gtk.Builder();
        try {
            builder.add_from_file(Config.PACKAGE_UI_DIR + "/preferences.ui");
            pref_dlg = (Gtk.Dialog)builder.get_object("dialog");
            setup_pref_dlg(builder);
        }
        catch(Error err) {
            return;
        }
    }
    pref_dlg.present();
}

}
