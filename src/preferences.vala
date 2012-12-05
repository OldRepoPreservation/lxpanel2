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

class PreferencesDialog : Gtk.Dialog {

    // setup the preference dialog
    public void setup_ui(Gtk.Builder builder) {
        
        // the view used to show applet layout
        applet_view = (Gtk.TreeView)builder.get_object("applet_view");
        applet_view.set_level_indentation(12);
        
        // The default reorder support of GtkTreeView is not suitable for
        // our need. We need to handle Dnd ourselves later. :-(
        // applet_view.set_reorderable(true);

        // create the data model for the applet view
        applet_store = new Gtk.TreeStore(3, typeof(GLib.Icon), typeof(string), typeof(Gtk.Widget));
        setup_applet_model();
        applet_view.set_model(applet_store);
        applet_view.expand_all();

        applet_view_sel = applet_view.get_selection();
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
        pref_btn.clicked.connect(on_item_pref);

        var move_up_btn = (Gtk.Button)builder.get_object("move_up_btn");
        move_up_btn.clicked.connect(on_move_up);

        var move_down_btn = (Gtk.Button)builder.get_object("move_down_btn");    
        move_down_btn.clicked.connect(on_move_down);

        ((Gtk.Button)builder.get_object("about_btn")).clicked.connect(on_about);

        applet_view.grab_focus();
    }

    protected override void response(int response_id) {
        if(response_id != 0) {
            // FIXME: save config here.
            destroy();
            pref_dlg = null;
        }
    }

    protected override void destroy() {
        // disconnect signal handlers
        foreach(unowned Panel panel in Panel.get_all()) {
            panel.applet_added.disconnect(on_panel_applet_added);
            panel.applet_removed.disconnect(on_panel_applet_removed);
            panel.applet_reordered.disconnect(on_panel_applet_reordered);
        }
        base.destroy(); // chain up to parent class
    }

    // find a Gtk.TreeIter by panel
    private bool find_panel(Panel panel, out Gtk.TreeIter iter) {
        Gtk.TreeIter _iter;
        if(applet_store.iter_children(out _iter, null)) {
            do {
                Panel? _panel = null;
                applet_store.get(_iter, 2, out _panel, -1);
                if(panel == _panel) {
                    iter = _iter;
                    return true;
                }
            }while(applet_store.iter_next(ref _iter));
        }
        return false;
    }

    // find a Gtk.TreeIter by panel and applet
    private bool find_applet(Panel panel, Applet applet, out Gtk.TreeIter iter) {
        Gtk.TreeIter panel_iter;
        if(find_panel(panel, out panel_iter)) {
            Gtk.TreeIter _iter;
            if(applet_store.iter_children(out _iter, panel_iter)) {
                do {
                    Applet? _applet = null;
                    applet_store.get(_iter, 2, out _applet, -1);
                    if(applet == _applet) {
                        iter = _iter;
                        return true;
                    }
                }while(applet_store.iter_next(ref _iter));
            }
        }
        return false;
    }

    // called if an applet is added to the panel
    private void on_panel_applet_added(Panel panel, Applet applet, int pos) {
        Gtk.TreeIter panel_iter;
        if(find_panel(panel, out panel_iter)) {
            Gtk.TreeIter applet_iter;
            var info = applet.get_info();
            applet_store.insert_with_values(out applet_iter, panel_iter,
                pos, 1, info.name, 2, applet, -1);
        }
    }

    // called if an applet is removed to the panel
    private void on_panel_applet_removed(Panel panel, Applet applet, int pos) {
        Gtk.TreeIter panel_iter;
        if(find_panel(panel, out panel_iter)) {
            Gtk.TreeIter iter;
            if(applet_store.iter_nth_child(out iter, panel_iter, pos)) {
                applet_store.remove(ref iter);
            }
        }
    }

    // called if an applet is reordered in the panel
    private void on_panel_applet_reordered(Panel panel, Applet applet, int new_pos) {
        Gtk.TreeIter iter;
        // TODO: reorder the item in the tree store
    }

    // fill the content of the applet data model GtkTreeStore
    private void setup_applet_model() {
        Gtk.TreeIter iter;
        foreach(unowned Panel panel in Panel.get_all()) {
            applet_store.append(out iter, null);
            applet_store.set(iter, 1, "Panel: " + panel.get_id(), 2, panel, -1);
            panel.applet_added.connect(on_panel_applet_added);
            panel.applet_removed.connect(on_panel_applet_removed);
            panel.applet_reordered.connect(on_panel_applet_reordered);

            foreach(unowned Applet applet in panel.get_applets()) {
                Gtk.TreeIter child_iter;
                unowned AppletInfo info = applet.get_info();
                applet_store.insert_with_values(out child_iter, iter,
                    -1, 1, info.name, 2, applet, -1);
            }
        }
    }

    // show the about dialog
    private void on_about(Gtk.Button button) {
        var builder = new Gtk.Builder();
        try {
            builder.add_from_file(Config.PACKAGE_UI_DIR + "/about.ui");
            var dlg = (Gtk.Dialog)builder.get_object("dlg");
            dlg.set_transient_for(this);
            dlg.response.connect((dlg, response) => {
                dlg.destroy();
            });
            dlg.run();
        }
        catch(Error err) {
        }
    }

    private void on_applet_view_sel_changed(Gtk.TreeSelection sel) {
        // TODO: update the sensitivity of buttons if needed
    }

    private void on_add_panel(Gtk.Button btn) {
        // TODO: add new panels here
    }

    private Panel? get_current_panel(out Gtk.TreeIter? panel_iter) {
        Panel? panel = null;
        Gtk.TreeIter iter;
        if(applet_view_sel.get_selected(null, out iter)) {
            for(;;) {
                Gtk.TreeIter parent;
                if(applet_store.iter_parent(out parent, iter)) {
                    iter = parent;
                }
                else { // topmost level
                    Gtk.Widget widget;
                    applet_store.get(iter, 2, out widget, -1);
                    panel = (Panel)widget;
                    if(panel_iter != null)
                        panel_iter = iter;
                    else // toplevel node
                        break;
                }
            }
        }
        return panel;
    }

    // [Add Applet] button is clicked
    private void on_add_applet(Gtk.Button btn) {
        Gtk.TreeIter panel_iter={0}, selected_iter;
        if(!applet_view_sel.get_selected(null, out selected_iter))
            return; // actually, this is not possible unless there is a bug.

        Gtk.Widget item = null;
        applet_store.get(selected_iter, 2, out item, -1);

        Panel panel = null;
        int insert_pos = -1;
        if(item is Panel) { // we selected a panel
            panel_iter = selected_iter;
            panel = (Panel)item;
        }
        else if(item is Applet) { // we selected an applet
            // get the parent panel iter
            if(applet_store.iter_parent(out panel_iter, selected_iter)) {
                applet_store.get(panel_iter, 2, out panel, -1);
                var selected_path = applet_store.get_path(selected_iter);
                if(selected_path != null) {
                    var indices = selected_path.get_indices();
                    insert_pos = indices[1];
                }
            }
        }
        var applet = choose_new_applet(this, (Panel)panel);
        if(applet != null) {
            panel.insert_applet(applet, insert_pos);
            // the data model applet_store will be updated in on_panel_applet_added()
            if(applet_store.iter_nth_child(out selected_iter, panel_iter, insert_pos))
                applet_view_sel.select_iter(selected_iter); // select the new item.
        }
    }

    private void on_remove(Gtk.Button btn) {
        // remove selected panel or applet
        Gtk.TreeIter iter;
        if(applet_view_sel.get_selected(null, out iter)) {
            Gtk.Widget? obj = null;
            applet_store.get(iter, 2, out obj, -1);
            if(obj != null) {
                if(obj is Applet) {
                    var applet = (Applet)obj;
                    var panel = (Panel)applet.get_toplevel();
                    if(panel != null)
                        panel.remove_applet(applet);
                    // the data model applet_store will be updated in on_panel_applet_removed()
                }
                else if(obj is Panel) {
                    var panel = (Panel)obj;
                    panel.destroy(); // destroy the panel
                    // TODO: prompt the user that the action cannot be undone.
                    applet_store.remove(ref iter); // remove the node from the model
                }
            }
        }
    }

    private void on_item_pref(Gtk.Button btn) {
        // open preference dialog for panel or applet
        Gtk.TreeIter iter;
        if(applet_view_sel.get_selected(null, out iter)) {
            Gtk.Widget? obj = null;
            applet_store.get(iter, 2, out obj, -1);
            if(obj != null) {
                if(obj is Applet) {
                    var applet = (Applet)obj;
                    applet.edit_config(this);
                }
                else if(obj is Panel) {
                    var panel = (Panel)obj;
                    
                }
            }
        }
    }

    private void on_move_up(Gtk.Button btn) {
        /*
        Gtk.TreeIter selected_iter;
        if(applet_view_sel.get_selected(null, out selected_iter)) {
            Gtk.TreeIter prev_iter = selected_iter;
            if(applet_store.iter_previous(ref prev_iter)) {
                Gtk.Widget widget;
                applet_store.get(selected_iter, 2, out widget, -1);
                if(widget != null) {
                    if(widget is Applet) {
                        Applet applet = (Applet)widget;
                        
                    }
                    else if(widget is Panel) {
                        Panel panel = (Panel)widget;
                        // FIXME: reorder Panel.all_panels list
                    }
                    applet_store.move_before(ref selected_iter, prev_iter);
                }
            }
            else {
            }
        }
        */
    }

    private void on_move_down(Gtk.Button btn) {
        // TODO: move items down
    }

    unowned Gtk.TreeView applet_view;
    unowned Gtk.TreeSelection applet_view_sel;
    Gtk.TreeStore applet_store;
}

private PreferencesDialog pref_dlg = null;

// Launch preference dialog for all panels
public void edit_preferences() {
    if(pref_dlg == null) {
        Gtk.Builder builder = null;
        pref_dlg = (PreferencesDialog)derived_widget_from_gtk_builder(
                        Config.PACKAGE_UI_DIR + "/preferences.ui",
                        "dialog",
                        typeof(Gtk.Dialog), typeof(PreferencesDialog),
                        out builder);
        if(pref_dlg == null)
            return;
        pref_dlg.setup_ui(builder);
    }
    pref_dlg.present();
}

}
