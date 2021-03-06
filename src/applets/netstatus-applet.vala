//      netstatus-applet.vala
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

public class NetstatusApplet : Applet {

	construct {
        event_box = new Gtk.EventBox();
		event_box.set_visible_window(false);
        add(event_box);
		image = new Gtk.Image.from_gicon(icon_idle, Gtk.IconSize.MENU);
		event_box.add(image);
		show_all();
	}

    public override void set_icon_size(int size) {
        base.set_icon_size(size);
		// Setting "pixel-size" property of Gtk.Image can override size
		// determined by Gtk.IconSize.
		image.pixel_size = size;
    }

	static construct {
		const string icon_error_names[] = {"network-error", "gnome-netstatus-error"};
		icon_error = new GLib.ThemedIcon.from_names(icon_error_names);

		const string icon_idle_names[] = {"network-idle", "gnome-netstatus-idle"};
		icon_idle = new GLib.ThemedIcon.from_names(icon_idle_names);

		const string icon_offline_names[] = {"network-offline", "gnome-netstatus-disconn"};
		icon_offline = new GLib.ThemedIcon.from_names(icon_offline_names);

		const string icon_rx_names[] = {"network-receive", "gnome-netstatus-rx"};
		icon_rx = new GLib.ThemedIcon.from_names(icon_rx_names);

		const string icon_tx_names[] = {"network-transmit", "gnome-netstatus-tx"};
		icon_tx = new GLib.ThemedIcon.from_names(icon_tx_names);

		const string icon_tx_rx_names[] = {"network-transmit-receive", "gnome-netstatus-txrx"};
		icon_tx_rx = new GLib.ThemedIcon.from_names(icon_tx_rx_names);
	}

	public override bool load_config(GMarkupDom.Node config_node) {
        base.load_config(config_node);
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "iface") {
				if(child.val != null) {
					iface = child.val;
				}
			}
			else if(child.name == "command") {
			}
		}
		return true;
	}

	public override void save_config(GMarkupDom.Node config_node) {
        base.save_config(config_node);
		if(iface != null)
			config_node.new_child("iface", iface);
	}

    public override void edit_config(Gtk.Window? parent_window) {
        // TODO: configuration dialog here
    }

    public override void customize_context_menu(Gtk.UIManager ui) {
        // TODO: add our own customize popup menu items here
    }

	public override void realize() {
		// timeout_id = Timeout.add_seconds(1, on_timeout);
		timeout_id = Timeout.add(500, on_timeout);
		base.realize();
	}

	public override void dispose() {
		if(timeout_id != 0) {
			Source.remove(timeout_id);
			timeout_id = 0;
		}
		base.dispose();
	}

	private bool on_timeout() {
		GTop.glibtop_netload netload;
		GTop.glibtop_get_netload(out netload, iface);
		bool tx = false, rx = false;

		if(netload.packets_in > last_rx) {
			rx = true;
			last_rx = netload.packets_in;
		}
		if(netload.packets_out > last_tx) {
			tx = true;
			last_tx = netload.packets_out;
		}

		unowned GLib.Icon icon = null;
		if(tx && rx)
			icon = icon_tx_rx;
		else if(tx)
			icon = icon_tx;
		else if(rx)
			icon = icon_rx;
		else
			icon = icon_idle;

		image.set_from_gicon(icon, Gtk.IconSize.MENU);
		// image.pixel_size = panel.get_icon_size();
		return true;
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(NetstatusApplet);
		applet_info.type_name = "netstatus";
		applet_info.name= _("Net Status");
		applet_info.icon = new ThemedIcon("network-wired");
		applet_info.description= _("Net Status");
        return (owned)applet_info;
	}

	uint timeout_id = 0;
	string iface = "eth0"; // network interface
    Gtk.EventBox event_box;
	Gtk.Image image;

	uint64 last_rx;
	uint64 last_tx;
	
	static GLib.Icon icon_error;
	static GLib.Icon icon_idle;
	static GLib.Icon icon_offline;
	static GLib.Icon icon_rx;
	static GLib.Icon icon_tx;
	static GLib.Icon icon_tx_rx;
}

}
