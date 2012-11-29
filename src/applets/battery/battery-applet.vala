//      battery-applet.vala
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

// NOTE: I found a bug of Vala dbus support.
// When the dbus interface is implemented in a type module, it'll be broken.
// Dbus iface cannot be correctly registered from a type module and can 
// only be done in the main program. Otherwise we get this error:
// "type_iface_ensure_dflt_vtable_Wm: assertion failed: (iface->data)"
//
// See here:
// http://osdir.com/ml/vala-list/2012-09/msg00128.html
// https://mail.gnome.org/archives/vala-list/2012-September/msg00125.html
// I've no idea how to overcome this, so I put the dbus code in the main
// lxpanel2 binary. :-(

// This battery applet relies on UPower, which is Linux-specific

namespace Lxpanel {

private class PowerDevice : Object {
	public PowerDevice(ObjectPath path, UPower.Device udevice) {
		this.path = path;
		this.udevice = udevice;
	}

	public void update() {
		// create a new proxy object to get all properties updated.
		// FIXME: this is a very poor way to get things done. :-(
		udevice = Bus.get_proxy_sync(BusType.SYSTEM,
									"org.freedesktop.UPower",
									path);
	}

	public ObjectPath path;
	public UPower.Device udevice;
}

public class BatteryApplet : Applet {
	construct {
        try{
		upower = Bus.get_proxy_sync(BusType.SYSTEM,
									"org.freedesktop.UPower",
									"/org/freedesktop/UPower");
		ObjectPath[] devices = null;
		upower.enumerate_devices(out devices);
		foreach(unowned ObjectPath device in devices) {
			on_device_added(device);
		}
		upower.device_added.connect(on_device_added);
		upower.device_changed.connect(on_device_changed);
		upower.device_removed.connect(on_device_removed);
        }catch(Error err) {
        }
	}

	public override void dispose() {
		if(upower != null) {
			upower.device_added.disconnect(on_device_added);
			upower.device_changed.disconnect(on_device_changed);
			upower.device_removed.disconnect(on_device_removed);
			upower = null;
		}
		if(batteries != null) {
			batteries = null;
		}
		if(line_powers != null) {
			line_powers = null;
		}
	}

	private void on_device_added(ObjectPath device_path) {
		stdout.printf("device added: %s\n", device_path);
		UPower.Device device = Bus.get_proxy_sync(BusType.SYSTEM,
										"org.freedesktop.UPower",
										device_path);
		if(device != null) {
			// device.refresh();
			stdout.printf("power_supply: %s\n", device.power_supply.to_string());
			switch(device.device_type) {
			case 1: // line power:
				line_powers.prepend(new PowerDevice(device_path, device));
				break;
			case 2: // battery:
				batteries.prepend(new PowerDevice(device_path, device));
				queue_resize();
				break;
			default: // others
				break;
			}
		}
	}

	private void on_device_changed(ObjectPath device_path) {
		bool found = false;
		foreach(unowned PowerDevice device in batteries) {
			if(device.path == device_path) {
				device.update();
				found = true;
				debug("power device changed: %lf", device.udevice.percentage);
				break;
			}
		}
		
		if(!found) {
			foreach(unowned PowerDevice device in line_powers) {
				if(device.path == device_path) {
					device.update();
					break;
				}
			}
		}
		
		// FIXME: we should update the changed device only.
		queue_draw();
	}

	private void on_device_removed(ObjectPath device_path) {
		bool found = false;
		foreach(unowned PowerDevice device in batteries) {
			if(device.path == device_path) {
				batteries.remove(device);
				found = true;
				break;
			}
		}
		if(!found) {
			foreach(unowned PowerDevice device in line_powers) {
				if(device.path == device_path) {
					line_powers.remove(device);
					break;
				}
			}
		}
	}

	protected override bool draw(Cairo.Context cr) {
		int width = get_allocated_width() - 2;
		int height = get_allocated_height() - 2;
		cr.save();
		cr.set_source_rgb(0,0,0);
		cr.rectangle(1, 1, width, height);
		cr.fill();
		if(batteries != null) {
			int left = 1;
			int cell_width = width / (int)batteries.length();
			cr.set_source_rgb(0,1,0);
			foreach(unowned PowerDevice device in batteries) {
				double percent = device.udevice.percentage;
				double bar_height = height * percent / 100;
				double bar_top = height - bar_height;
				cr.rectangle(left + 1, 1 + bar_top + 1, cell_width - 2, bar_height - 2);
				cr.fill();
				left += cell_width;
			}
		}
		cr.restore();
		return true;
	}

    // currently, using width_for_height/height_for_width is broken
	protected override Gtk.SizeRequestMode get_request_mode() {
		Gtk.SizeRequestMode mode;
		/*
		if(orientation == Gtk.Orientation.HORIZONTAL)
			mode = Gtk.SizeRequestMode.WIDTH_FOR_HEIGHT;
		else
			mode = Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
		*/
		mode = Gtk.SizeRequestMode.CONSTANT_SIZE;
		return mode;
	}

    /*
	protected override void get_preferred_width_for_height(int height, out int min_width, out int natral_width) {
		//int cell_width = (height / 1);
		//natral_width = min_width = (int)batteries.length() * cell_width;
	}
    */

    protected override void get_preferred_width(out int min, out int natural) {
        if(get_panel_orientation() == Gtk.Orientation.HORIZONTAL)
            min = natural = get_icon_size() / 3;
        else
            base.get_preferred_width(out min, out natural);
    }

    protected override void get_preferred_height(out int min, out int natural) {
        if(get_panel_orientation() == Gtk.Orientation.VERTICAL)
            base.get_preferred_height(out min, out natural);
        else
            min = natural = get_icon_size() / 3;
    }

	UPower.UPower upower;
	List<PowerDevice> batteries;
	List<PowerDevice> line_powers;
}

}

// called by lxpanel when loading the module
[ModuleInit]
public Type load(GLib.TypeModule module) {
	// FIXME: ABI compatibility check here
	return typeof(Lxpanel.BatteryApplet);
}

// called by lxpanel before unloading the module
public void unload() {
}
