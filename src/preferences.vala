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

        // the left view used to show panels
        setup_panel_view(builder);

        // add & remove panel buttons
        var add_panel_btn = (Gtk.Button)builder.get_object("add_panel_btn");
        add_panel_btn.clicked.connect(on_add_panel);
        var remove_panel_btn = (Gtk.Button)builder.get_object("remove_panel_btn");
        remove_panel_btn.clicked.connect(on_remove_panel);

        // about button
        ((Gtk.Button)builder.get_object("about_btn")).clicked.connect(on_about);

        // [Position] page
        setup_position_page(builder);
        
        // [Size] page
        setup_size_page(builder);

        // [Applets] page
        setup_applets_page(builder);

        // [Advanced] page
        setup_advanced_page(builder);
        
        // [Global] page
        setup_global_page(builder);
    }

    private void on_panel_view_sel_changed(Gtk.TreeSelection tree_sel) {
        Gtk.TreeIter iter;
        if(panel_view_sel.get_selected(null, out iter)) {
            Panel selected_panel;
            panel_store.get(iter, 1, out selected_panel, -1);
            update_for_panel(selected_panel);
        }
    }

    private void setup_panel_view(Gtk.Builder builder) {
        // the view used to show panels
        panel_view = (Gtk.TreeView)builder.get_object("panel_view");
        // create the data model for the panel view
        panel_store = new Gtk.ListStore(2, typeof(string), typeof(Panel));
        panel_view.set_model(panel_store);
        panel_view_sel = panel_view.get_selection();
        panel_view_sel.set_mode(Gtk.SelectionMode.BROWSE);
        panel_view_sel.changed.connect(on_panel_view_sel_changed);

        Gtk.TreeIter iter;
        foreach(unowned Panel panel in Panel.get_all()) {
            panel_store.append(out iter);
            panel_store.set(iter, 0, panel.get_id(), 1, panel, -1);
        }
    }

    private void setup_position_page(Gtk.Builder builder) {

        edge_combo = (Gtk.ComboBox)builder.get_object("edge_combo");
        edge_combo.changed.connect((combo) => {
            if(current_panel != null) {
                int active = edge_combo.get_active();
                current_panel.set_position((Gtk.PositionType)active);
            }
        });

        alignment_spin = (Gtk.SpinButton)builder.get_object("alignment_spin");
        alignment_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_alignment(spin.get_value());
        });

        left_margin_spin = (Gtk.SpinButton)builder.get_object("left_margin_spin");
        left_margin_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_left_margin((int)spin.get_value());
        });

        top_margin_spin = (Gtk.SpinButton)builder.get_object("top_margin_spin");
        top_margin_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_top_margin((int)spin.get_value());
        });

        right_margin_spin = (Gtk.SpinButton)builder.get_object("right_margin_spin");
        right_margin_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_right_margin((int)spin.get_value());
        });

        bottom_margin_spin = (Gtk.SpinButton)builder.get_object("bottom_margin_spin");
        bottom_margin_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_bottom_margin((int)spin.get_value());
        });

        monitor_combo = (Gtk.ComboBox)builder.get_object("monitor_combo");
        var monitor_model = (Gtk.ListStore)monitor_combo.get_model();
        var screen = get_screen();
        var n_monitors = screen.get_n_monitors();
        int i;
        for(i = 0; i < n_monitors; ++i) {
            var plug_name = screen.get_monitor_plug_name(i);
            string name = @"Monitor $i: $plug_name";
            monitor_model.insert_with_values(null, -1, 0, name, -1);
        }
        monitor_combo.changed.connect((combo) => {
            if(current_panel != null) {
                int monitor = combo.get_active();
                current_panel.set_monitor(monitor);
            }
        });
        monitor_combo.set_sensitive(!current_panel.get_span_monitors());

        span_monitors_check = (Gtk.ToggleButton)builder.get_object("span_monitors_check");
        span_monitors_check.toggled.connect((btn) => {
            var toggled = btn.get_active();
            if(current_panel != null)
                current_panel.set_span_monitors(toggled);
            monitor_combo.set_sensitive(!toggled);
        });
    }

    private void setup_size_page(Gtk.Builder builder) {
        length_spin = (Gtk.SpinButton)builder.get_object("length_spin");
        length_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_length((int)spin.get_value());
        });

        length_unit_combo = (Gtk.ComboBox)builder.get_object("length_unit_combo");
        length_unit_combo.changed.connect((combo) => {
            if(current_panel != null) {
                const SizeMode modes[] = {SizeMode.AUTO, SizeMode.PIXEL, SizeMode.PERCENT};
                SizeMode mode = modes[combo.get_active()];
                current_panel.set_length_mode(mode);
                length_spin.set_sensitive(mode != SizeMode.AUTO);
            }
        });

        thickness_spin = (Gtk.SpinButton)builder.get_object("thickness_spin");
        thickness_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_thickness((int)spin.get_value());
        });

        icon_size_spin = (Gtk.SpinButton)builder.get_object("icon_size_spin");
        icon_size_spin.value_changed.connect((spin) => {
            if(current_panel != null)
                current_panel.set_icon_size((int)spin.get_value());
        });
    }

    protected void on_applet_view_drag_begin(Gtk.Widget view, Gdk.DragContext ctx) {
        print("drag_source::drag-begin\n");
	}

    protected void on_applet_view_drag_end(Gtk.Widget view, Gdk.DragContext ctx) {
	}

    protected bool on_applet_view_drag_drop(Gtk.Widget view, Gdk.DragContext ctx, int x, int y, uint time) {
        print("drag_dest::drag-drop\n");
        return true;
	}

    protected bool on_applet_view_drag_motion(Gtk.Widget view, Gdk.DragContext ctx, int x, int y, uint time) {
        print("drag_dest::drag-motion\n");
        return true;
	}

    private void setup_applets_page(Gtk.Builder builder) {
        // the view used to show applet layout
        applet_view = (Gtk.TreeView)builder.get_object("applet_view");
        applet_view.set_level_indentation(12);
        applet_view.set_reorderable(true);
        applet_view_sel = applet_view.get_selection();
        applet_view_sel.set_mode(Gtk.SelectionMode.BROWSE);
        applet_view_sel.changed.connect(on_applet_view_sel_changed);

		// glade does not support "gicon" attribute yet. set it manually
		var name_col = (Gtk.TreeViewColumn)builder.get_object("applet_name_column");
		var icon_renderer = (Gtk.CellRendererPixbuf)builder.get_object("applet_icon_renderer");
		name_col.add_attribute(icon_renderer, "gicon", 0);

        // add, edit, remove, and move applets
        var add_applet_btn = (Gtk.Button)builder.get_object("add_applet_btn");
        add_applet_btn.clicked.connect(on_add_applet);
        var remove_btn = (Gtk.Button)builder.get_object("remove_applet_btn");
        remove_btn.clicked.connect(on_remove_applet);
        var pref_btn = (Gtk.Button)builder.get_object("pref_btn");
        pref_btn.clicked.connect(on_applet_pref);
        var move_up_btn = (Gtk.Button)builder.get_object("move_up_btn");
        move_up_btn.clicked.connect(on_move_up);
        var move_down_btn = (Gtk.Button)builder.get_object("move_down_btn");    
        move_down_btn.clicked.connect(on_move_down);
    }

    private void setup_advanced_page(Gtk.Builder builder) {
        // FIXME: what's this for?
        as_dock_check = (Gtk.ToggleButton)builder.get_object("as_dock_check");
        reserve_space_check = (Gtk.ToggleButton)builder.get_object("reserve_space_check");
        reserve_space_check.toggled.connect((toggle_btn) => {
            if(current_panel != null)
                current_panel.set_reserve_space(reserve_space_check.get_active());
        });

        autohide_check = (Gtk.ToggleButton)builder.get_object("autohide_check");
        autohide_check.toggled.connect((toggle_btn) => {
            if(current_panel != null)
                current_panel.set_auto_hide(autohide_check.get_active());
        });

        min_size_spin = (Gtk.SpinButton)builder.get_object("min_size_spin");
    }

	private void setup_themes(Gtk.Builder builder) {
		// setup theme combobox
		theme_combo = (Gtk.ComboBox)builder.get_object("theme_combo");
		// load themes

		/*
		// search for the user specific themes first
		var theme_dir = Path.build_filename(Environment.get_home_dir(), ".theme", theme_name, "lxpanel", null);
		if(FileUtils.test(theme_dir + "/lxpanel.css", FileTest.IS_REGULAR))
			return theme_dir;
		// try system-wide theme dirs
		var data_dirs = Environment.get_system_data_dirs();
		foreach(unowned string data_dir in data_dirs) {
			theme_dir = Path.build_filename(data_dir, "themes", theme_name, "lxpanel", null);
			if(FileUtils.test(theme_dir + "/lxpanel.css", FileTest.IS_REGULAR))
				return theme_dir;
		}
		*/
		theme_combo.changed.connect((combo) => {
			Gtk.TreeIter iter;
			
		});

		use_theme_radio = (Gtk.RadioButton)builder.get_object("use_theme_radio");
		use_theme_radio.toggled.connect((btn) => {
		});

		no_theme_radio = (Gtk.RadioButton)builder.get_object("no_theme_radio");
		no_theme_radio.toggled.connect((btn) => {
			var no_theme = btn.get_active();
			theme_combo.set_sensitive(!no_theme);
		});
	}

    private void setup_global_page(Gtk.Builder builder) {

		setup_themes(builder);

		// custom commands
        file_manager_entry = (Gtk.Entry)builder.get_object("file_manager_entry");
        var cmd = Panel.get_file_manager();
        if(cmd != null)
			file_manager_entry.set_text(cmd);
        file_manager_entry.changed.connect((editable) => {
			var entry = (Gtk.Entry)editable;
			Panel.set_file_manager(entry.get_text());
		});

        terminal_entry = (Gtk.Entry)builder.get_object("terminal_entry");
        cmd = Panel.get_terminal_command();
        if(cmd != null)
			terminal_entry.set_text(cmd);
        terminal_entry.changed.connect((editable) => {
			var entry = (Gtk.Entry)editable;
			Panel.set_terminal_command(entry.get_text());
		});

        logout_entry = (Gtk.Entry)builder.get_object("logout_entry");
        cmd = Panel.get_logout_command();
        if(cmd != null)
			logout_entry.set_text(cmd);
        logout_entry.changed.connect((editable) => {
			var entry = (Gtk.Entry)editable;
			Panel.set_logout_command(entry.get_text());
		});
    }

    protected override void response(int response_id) {
        if(response_id != 0) {
            // FIXME: save config here.
            destroy();
            pref_dlg = null;
        }
    }

    protected override void destroy() {
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

    // called from the panel if an applet is added to it
    private void on_panel_applet_added(Panel panel, Applet applet, int pos) {
		Gtk.TreeIter applet_iter;
		var info = applet.get_info();
		// block the row-inserted handler here
		SignalHandler.block(applet_store, applet_store_row_inserted_id);
		// insert the applet in the list store
		applet_store.insert_with_values(out applet_iter, pos,
			1, info.name, 2, applet, -1);
		SignalHandler.unblock(applet_store, applet_store_row_inserted_id);
    }

    // called from the panel if an applet is removed from it
    private void on_panel_applet_removed(Panel panel, Applet applet, int pos) {
		Gtk.TreeIter iter;
		if(applet_store.iter_nth_child(out iter, null, pos)) {
			// block the row-deleted handler here
			SignalHandler.block(applet_store, applet_store_row_deleted_id);
			// remove the applet from the list store
			applet_store.remove(iter);
			SignalHandler.unblock(applet_store, applet_store_row_deleted_id);
		}
    }

    // called from the panel if an applet is reordered in it
    private void on_panel_applet_reordered(Panel panel, Applet applet, int new_pos) {
        Gtk.TreeIter iter;
        // TODO: reorder the item in the tree store
        // should we emulate reorder with insert/delete?
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

	// Normally, we get row-inserted everytime a new row is inserted into applet_store.
	// However, we block the signal handler everytime before adding new items.
	// So the only case we receive this signal is induced by "reordering rows by dnd".
	private void on_applet_store_row_inserted(Gtk.TreeModel model, Gtk.TreePath tree_path, Gtk.TreeIter iter) {
		// so the "row-inserted" signal actually represent a "reorder" operation.
		// it's emitted before "row-deleted"
		// print("row inserted\n");
		if(current_panel != null) {
			applet_store_row_reorder_pos = tree_path.get_indices()[0];
		}
		else
			applet_store_row_reorder_pos = -1;
	}

	// Normally, we get row-deleted everytime a row is removed from applet_store.
	// However, we block the signal handler everytime before removing items.
	// So the only case we receive this signal is induced by "reordering rows by dnd".
	private void on_applet_store_row_deleted(Gtk.TreeModel model, Gtk.TreePath tree_path) {
		// so the "row-deleted" signal actually represent a "reorder" operation.
		// it's emitted after "row-inserted"
		// print("row deleted\n");
		if(current_panel != null) {
			unowned Applet applet_to_reorder;
			var all_applets = current_panel.get_applets();
			int old_pos = tree_path.get_indices()[0];
			// if the new row is inserted before the old row to be removed,
			// old_pos is increased by 1 because of the insertion.
			// so we need to --old_pos to get the correct applet position in the panel
			if(applet_store_row_reorder_pos < old_pos)
				--old_pos;
			else if(applet_store_row_reorder_pos > old_pos)
				--applet_store_row_reorder_pos;
			applet_to_reorder = all_applets.nth_data(old_pos);
			if(applet_to_reorder != null) {
				current_panel.reorder_applet(applet_to_reorder, applet_store_row_reorder_pos);
				// select the reordered item
				Gtk.TreeIter iter;
				if(applet_store.iter_nth_child(out iter, null, applet_store_row_reorder_pos))
					applet_view_sel.select_iter(iter);
			}
		}
		applet_store_row_reorder_pos = -1;
	}

    private void update_for_panel(Panel panel) {

        if(current_panel != null) {
			// disconnect signal handlers
			current_panel.applet_added.disconnect(on_panel_applet_added);
			current_panel.applet_removed.disconnect(on_panel_applet_removed);
			current_panel.applet_reordered.disconnect(on_panel_applet_reordered);
			// set current_panel to null first, so when we set new values to widgets
			// the triggered signal handlers don't do anything.
			current_panel = null;
		}

        // [Position] page
        edge_combo.set_active((int)panel.get_position());
        alignment_spin.set_value(panel.get_alignment());
        left_margin_spin.set_value(panel.get_left_margin());
        top_margin_spin.set_value(panel.get_top_margin());
        right_margin_spin.set_value(panel.get_right_margin());
        bottom_margin_spin.set_value(panel.get_bottom_margin());
        monitor_combo.set_active(panel.get_monitor());
        span_monitors_check.set_active(panel.get_span_monitors());

        // [Size] page
        length_spin.set_value(panel.get_length());
        int i;
        switch(panel.get_length_mode()) {
        case SizeMode.AUTO:
        default:
			i = 0;
			break;
        case SizeMode.PIXEL:
            i = 1;
            break;
        case SizeMode.PERCENT:
            i = 2;
            break;
        }
        length_unit_combo.set_active(i);
        length_spin.set_sensitive(i != 0);
        thickness_spin.set_value(panel.get_thickness());
        icon_size_spin.set_value(panel.get_icon_size());

        // [Applets] page
        // create the data model for the applet view
        applet_store = new Gtk.ListStore(3, typeof(GLib.Icon), typeof(string), typeof(Applet));
        foreach(unowned Applet applet in panel.get_applets()) {
            Gtk.TreeIter child_iter;
            unowned AppletInfo info = applet.get_info();
            applet_store.insert_with_values(out child_iter, -1,
				0, info.icon, 1, info.name, 2, applet, -1);
        }
        applet_view.set_model(applet_store);
        applet_view.expand_all();
        applet_store_row_inserted_id = applet_store.row_inserted.connect(on_applet_store_row_inserted);
        applet_store_row_deleted_id = applet_store.row_deleted.connect(on_applet_store_row_deleted);

        // [Advanced] page
        // as_dock_check.set_active(panel.get_
        reserve_space_check.set_active(panel.get_reserve_space());
        autohide_check.set_active(panel.get_auto_hide());

        current_panel = panel;
		current_panel.applet_added.connect(on_panel_applet_added);
		current_panel.applet_removed.connect(on_panel_applet_removed);
		current_panel.applet_reordered.connect(on_panel_applet_reordered);
    }

    public void set_current_panel(Panel new_panel) {
        Gtk.TreeIter iter;
        if(panel_store.get_iter_first(out iter)) {
            do {
                Panel panel;
                panel_store.get(iter, 1, out panel, -1);
                if(panel == new_panel) {
                    panel_view_sel.select_iter(iter);
                    break;
                }
            }while(panel_store.iter_next(ref iter));
        }
    }

    public Panel? get_current_panel(out Gtk.TreeIter? panel_iter) {
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

	private string ask_for_panel_id(string default_id) {
		string new_id = null;
		var dlg = new Gtk.Dialog.with_buttons(_("Panel Name"), this, 0,
			Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
			Gtk.STOCK_OK, Gtk.ResponseType.OK, null);
		dlg.set_border_width(10);
		var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
		var content = dlg.get_content_area();
		content.add(vbox);
		vbox.pack_start(new Gtk.Label("Please enter a new name for the panel:"), false, true, 0);
		var entry = new Gtk.Entry();
		vbox.pack_start(entry, false, true, 0);
		entry.set_text(default_id);
		vbox.show_all();

		for(;;) {
			if(dlg.run() == Gtk.ResponseType.OK) {
				var input = entry.get_text();
				if(input != "" && Panel.is_id_unique(input)) {
					new_id = input;
					break;
				}
			}
			else
				break;
		}
		dlg.destroy();
		return new_id;
	}

    // [Add Panel] button is clicked
    private void on_add_panel(Gtk.Button btn) {
		// FIXME: ask the user to input a new name for the panel
		string panel_id = ask_for_panel_id(_("New Panel"));
		Gtk.TreeIter iter;
		if(panel_view_sel.get_selected(null, out iter) && panel_id != null) {
			var tree_path = panel_store.get_path(iter);
			if(tree_path != null) {
				int insert_pos = tree_path.get_indices()[0];
				Panel panel = Panel.add_panel(panel_id, insert_pos);
				if(panel != null) {
					panel_store.insert_with_values(null, insert_pos,
						0, panel_id, 1, panel, -1);
				}
			}
		}
    }

    // [Remove Panel] button is clicked
    private void on_remove_panel(Gtk.Button btn) {
		if(panel_store.iter_n_children(null) > 1) {
			Gtk.TreeIter iter;
			if(panel_view_sel.get_selected(null, out iter)) {
				current_panel.destroy();
				panel_store.remove(iter);
			}
		}
		else {
			var msg = new Gtk.MessageDialog(this, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK,
						_("You should have at least one panel"));
			msg.run();
			msg.destroy();
		}
    }

    // [Add Applet] button is clicked
    private void on_add_applet(Gtk.Button btn) {
		if(current_panel != null) {
			Gtk.TreeIter selected_iter;
			int insert_pos = 0;
			if(applet_view_sel.get_selected(null, out selected_iter)) {
				var selected_path = applet_store.get_path(selected_iter);
				if(selected_path != null) {
					var indices = selected_path.get_indices();
					insert_pos = indices[0];
				}
			}
			var applet = choose_new_applet(this, current_panel);
			if(applet != null) {
				current_panel.insert_applet(applet, insert_pos);
				// the data model applet_store will be updated in on_panel_applet_added()
				if(applet_store.iter_nth_child(out selected_iter, null, insert_pos))
					applet_view_sel.select_iter(selected_iter); // select the new item.
			}
		}
    }

	// [Remove Applet] button is clicked
    private void on_remove_applet(Gtk.Button btn) {
        // remove selected applet
        if(current_panel != null) {
			Gtk.TreeIter iter;
			if(applet_view_sel.get_selected(null, out iter)) {
				Applet applet = null;
				applet_store.get(iter, 2, out applet, -1);
				current_panel.remove_applet(applet);
			}
		}
    }

	// [Preferences] button is clicked for a selected applet
    private void on_applet_pref(Gtk.Button btn) {
        // open preference dialog for applet
        if(current_panel != null) {
			Gtk.TreeIter iter;
			if(applet_view_sel.get_selected(null, out iter)) {
				Applet applet = null;
				applet_store.get(iter, 2, out applet, -1);
                applet.edit_config(this);
			}
		}
    }

    private void on_move_up(Gtk.Button btn) {
        // TODO: move items up
    }

    private void on_move_down(Gtk.Button btn) {
        // TODO: move items down
    }

    unowned Panel current_panel;

    unowned Gtk.TreeView panel_view;
    unowned Gtk.TreeSelection panel_view_sel;
    Gtk.ListStore panel_store;

    unowned Gtk.TreeView applet_view;
    unowned Gtk.TreeSelection applet_view_sel;
    Gtk.ListStore applet_store;
    ulong applet_store_row_inserted_id;
    ulong applet_store_row_deleted_id;
    int applet_store_row_reorder_pos = -1;

    unowned Gtk.ComboBox edge_combo;
    unowned Gtk.SpinButton alignment_spin;
    unowned Gtk.SpinButton left_margin_spin;
    unowned Gtk.SpinButton top_margin_spin;
    unowned Gtk.SpinButton right_margin_spin;
    unowned Gtk.SpinButton bottom_margin_spin;
    unowned Gtk.ComboBox monitor_combo;
    unowned Gtk.ToggleButton span_monitors_check;

    unowned Gtk.SpinButton length_spin;
    unowned Gtk.ComboBox length_unit_combo;
    unowned Gtk.SpinButton thickness_spin;
    unowned Gtk.SpinButton icon_size_spin;

    unowned Gtk.ToggleButton as_dock_check;
    unowned Gtk.ToggleButton reserve_space_check;
    unowned Gtk.ToggleButton autohide_check;
    unowned Gtk.SpinButton min_size_spin;

	unowned Gtk.ComboBox theme_combo;
	unowned Gtk.RadioButton use_theme_radio;
	unowned Gtk.RadioButton no_theme_radio;
    unowned Gtk.Entry file_manager_entry;
    unowned Gtk.Entry terminal_entry;
    unowned Gtk.Entry logout_entry;
}

private PreferencesDialog pref_dlg = null;

// Launch preference dialog for all panels
public void edit_preferences(Panel? panel) {
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
        if(panel != null)
            pref_dlg.set_current_panel(panel);
    }
    pref_dlg.present();
}

}
