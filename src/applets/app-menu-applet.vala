//      app-menu-applet.vala
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

public class AppMenuApplet : Applet {

	construct {
        button = new MenuButton();
		button.set_tooltip_text(_("Applications"));
		button.set_icon_pixbuf(new Gdk.Pixbuf.from_file("/usr/share/lubuntu/images/lubuntu-logo.png"));
        pack_start(button, false, true, 0);
        button.show();

		var menu = new Gtk.Menu();
		menu.show_all();
		button.set_menu(menu);

		menu_cache = MenuCache.Cache.lookup("applications.menu");
		if(menu_cache != null) {
			menu_cache_reload_notify = menu_cache.add_reload_notify(() => {
				reload_menu();
			});
		}
	}

	protected override void dispose() {
		if(menu_cache != null) {
			menu_cache.remove_reload_notify(menu_cache_reload_notify);
			menu_cache_reload_notify = null;
			menu_cache = null;
		}
	}

	private void add_menu_items(Gtk.Menu menu, MenuCache.Dir dir) {
		foreach(unowned MenuCache.Item item in dir.get_children()) {
			MenuCache.ItemType type = item.get_type();
			if(type == MenuCache.ItemType.SEP) {
				menu.append(new Gtk.SeparatorMenuItem());
				continue;
			}
			else {
				Gtk.ImageMenuItem mi = new Gtk.ImageMenuItem.with_label(item.get_name());
				mi.set_always_show_image(true);
				mi.set_image(new Gtk.Image.from_icon_name(item.get_icon(), Gtk.IconSize.MENU));
				mi.set_tooltip_text(item.get_comment());
				mi.set_data("MenuCacheItem", item);
				menu.append(mi);
				if(type == MenuCache.ItemType.APP) {
					mi.activate.connect(on_app_menu_item_activated);
				}
				else if(type == MenuCache.ItemType.DIR) {
					var submenu = new Gtk.Menu();
					add_menu_items(submenu, (MenuCache.Dir)item);
					mi.set_submenu(submenu);
				}
			}
		}
		menu.show_all();
	}
	
	private void on_app_menu_item_activated(Gtk.MenuItem menu_item) {
		MenuCache.App app = menu_item.get_data("MenuCacheItem");
		var desktop_file = app.get_file_path();
		// use GDesktopAppInfo here
		var appinfo = new DesktopAppInfo.from_filename(desktop_file);
		appinfo.launch(null, null);
	}

	private void reload_menu() {
		unowned MenuCache.Dir dir = menu_cache.get_root_dir();
		Gtk.Menu menu = (Gtk.Menu)button.get_menu();
		add_menu_items(menu, dir);
	}

    public void popup_menu() {
        button.clicked();
    }

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(AppMenuApplet);
		applet_info.type_name = "appmenu";
		applet_info.name= _("AppMenu");
		applet_info.description= _("Application Menu");
        return (owned)applet_info;
	}

	private MenuCache.Cache? menu_cache;
	private void* menu_cache_reload_notify;
    MenuButton button;
}

}
