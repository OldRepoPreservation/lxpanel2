//      mounts-applet.vala
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

public class MountsApplet : Applet {

	construct {
        button = new MenuButton();
        add(button);
        button.show();

		menu = new Gtk.Menu();
		button.set_menu(menu);
		button.set_tooltip_text(_("Mounted Volumes"));

		monitor = VolumeMonitor.get();
		monitor.volume_added.connect(on_volume_added);
		monitor.volume_removed.connect(on_volume_removed);
		monitor.volume_changed.connect(on_volume_changed);

		monitor.mount_added.connect(on_mount_added);
		monitor.mount_removed.connect(on_mount_removed);
		monitor.mount_changed.connect(on_mount_changed);

		List<Volume> volumes = monitor.get_volumes();
		foreach(unowned Volume volume in volumes) {
			on_volume_added(monitor, volume);
		}
	}

	protected override void dispose() {
		if(monitor != null) {
			monitor.volume_added.disconnect(on_volume_added);
			monitor.volume_removed.disconnect(on_volume_removed);
			monitor.volume_changed.disconnect(on_volume_changed);

			monitor.mount_added.disconnect(on_mount_added);
			monitor.mount_removed.disconnect(on_mount_removed);
			monitor.mount_changed.disconnect(on_mount_changed);

			monitor = null;
		}
		
		if(menu != null) {
			menu.destroy();
			menu = null;
		}
        base.dispose();
	}

	private unowned Gtk.ImageMenuItem? find_item_by_volume(Volume volume) {
		var children = menu.get_children();
		foreach(unowned Gtk.Widget child in children) {
			unowned Gtk.ImageMenuItem item = (Gtk.ImageMenuItem)child;
			if(item.get_data<Volume>("volume") == volume)
				return item;
		}
		return null;
	}


	private void on_mount(Gtk.MenuItem item) {
		Volume? volume = item.get_data<Volume>("volume");
		if(volume != null) {
			volume.mount.begin(0, null, null, (obj, res) => {
				volume.mount.end(res);
			});
		}
	}

	private void on_unmount(Gtk.MenuItem item) {
		Volume? volume = item.get_data<Volume>("volume");
		if(volume != null) {
			var mount = volume.get_mount();
			if(mount != null) {
				mount.unmount_with_operation.begin(0, null, null, (obj, res) => {
					mount.unmount_with_operation.end(res);
				});
			}
		}
	}

	private void on_eject(Gtk.MenuItem item) {
		Volume? volume = item.get_data<Volume>("volume");
		if(volume != null) {
			volume.eject_with_operation.begin(0, null, null, (obj, res) => {
				volume.eject_with_operation.end(res);
			});
		}
	}

	private void open_volume(Volume volume, bool auto_mount = false) {
		var mount = volume.get_mount();
		if(mount != null) {
			launch_folder(mount.get_root(), get_screen());
		}
		else if(auto_mount) {
			volume.mount.begin(0, null, null, (obj, res) => {
				open_volume(volume, false);
				volume.mount.end(res);
			});
		}
	}

	private void on_open(Gtk.MenuItem item) {
		Volume? volume = item.get_data<Volume>("volume");
		if(volume != null) {
			open_volume(volume, true);
		}
	}

	private Gtk.Menu create_submenu(Volume volume) {
		var mount = volume.get_mount();
		var sub_menu = new Gtk.Menu();
		var item = new Gtk.MenuItem.with_label(_("Open"));
		item.set_data<Volume>("volume", volume);
		item.activate.connect(on_open);
		sub_menu.append(item);
		sub_menu.append(new Gtk.SeparatorMenuItem());

		if(mount != null) {
			item = new Gtk.MenuItem.with_label(_("Unmount"));
			item.activate.connect(on_unmount);
		}
		else {
			item = new Gtk.MenuItem.with_label(_("Mount"));
			item.activate.connect(on_mount);
		}
		item.set_data<Volume>("volume", volume);
		sub_menu.append(item);

		if(volume.can_eject()) {
			item = new Gtk.MenuItem.with_label(_("Eject"));
			item.set_data<Volume>("volume", volume);
			item.activate.connect(on_eject);
			sub_menu.append(item);
		}
		sub_menu.show_all();
		return sub_menu;
	}

	private void on_volume_added(VolumeMonitor volmon, Volume volume) {
        if(find_item_by_volume(volume) == null) {
            var item = new Gtk.ImageMenuItem.with_label(volume.get_name());
            var image = new Gtk.Image.from_gicon(volume.get_icon(), Gtk.IconSize.MENU);
            item.set_image(image);
            item.show();
            item.set_data<Volume>("volume", volume);
            // create submenu for the volume
            var sub_menu = create_submenu(volume);
            item.set_submenu(sub_menu);
            menu.append(item);
        }
	}

	private void on_volume_removed(VolumeMonitor volmon, Volume volume) {
		unowned Gtk.ImageMenuItem item = find_item_by_volume(volume);
		if(item != null) {
			item.destroy();
		}
	}

	private void update_item(Gtk.ImageMenuItem item, Volume volume) {
		unowned Gtk.Image image = (Gtk.Image)item.get_image();
		image.set_from_gicon(volume.get_icon(), Gtk.IconSize.MENU);
		item.set_label(volume.get_name());
		// Recreate the sub menu.
		// FIXME: This is convinient but less efficient
		var new_sub_menu = create_submenu(volume);
		item.set_submenu(new_sub_menu);
	}

	private void on_volume_changed(VolumeMonitor volmon, Volume volume) {
		unowned Gtk.ImageMenuItem item = find_item_by_volume(volume);
		if(item != null) {
			update_item(item, volume);
		}
	}

	private void on_mount_added(VolumeMonitor volmon, Mount mount) {
		Volume? volume = mount.get_volume();
		unowned Gtk.ImageMenuItem item = null;
		if(volume != null) {
			// if a volume is mounted, in "volume-changed" handler,
			// volume.get_mount() still returns null.
			// only when "mount-added" is emitted can we know that
			// the volume is already mounted.
			item = find_item_by_volume(volume);
			if(item != null) {
				// recreate sub menu
				var new_sub_menu = create_submenu(volume);
				item.set_submenu(new_sub_menu);
			}
		}
	}

	private void on_mount_removed(VolumeMonitor volmon, Mount mount) {
	}

	private void on_mount_changed(VolumeMonitor volmon, Mount mount) {
	}

	public override void set_icon_size(int size) {
        base.set_icon_size(size);
		button.set_gicon(new ThemedIcon("drive-removable-media"), size);
	}

	public bool load_config(GMarkupDom.Node config_node) {
        base.load_config(config_node);
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "show_mounts") {
				show_mounts = bool.parse(child.val);
			}
		}
		return true;
	}

	public void save_config(GMarkupDom.Node config_node) {
        base.save_config(config_node);
		if(show_mounts)
			config_node.new_child("show_mounts", show_mounts.to_string());
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(MountsApplet);
		applet_info.type_name = "mounts";
		applet_info.name= _("Mounts");
		applet_info.icon = new ThemedIcon("drive-removable-media");
		applet_info.description= _("Show mounted volumes");
		return (owned)applet_info;
	}

	VolumeMonitor? monitor;
    MenuButton button;
	Gtk.Menu? menu;
	bool show_mounts;
}

}
