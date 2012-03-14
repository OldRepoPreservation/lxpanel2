//      upower.vala
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

namespace UPower {

[DBus (name = "org.freedesktop.UPower")]
public interface UPower : Object {

	public abstract void enumerate_devices(out ObjectPath[] devices) throws IOError;

	public abstract string daemon_version {owned get;}
	public abstract bool can_suspend {get;}
	public abstract bool can_hibernate {get;}
	public abstract bool on_battery {get;}
	public abstract bool on_low_battery {get;}
	public abstract bool lid_is_closed {get;}
	public abstract bool lid_is_present {get;}
	public abstract bool lid_force_sleep {get;}
	public abstract bool lid_docked {get;}

	public signal void device_added(ObjectPath device);
	public signal void device_removed(ObjectPath device);
	public signal void device_changed(ObjectPath device);
	public signal void changed();
	public signal void sleeping();
	public signal void notify_sleep(string action);
	public signal void resuming();
	public signal void notify_resume(string action);
}

[DBus (name = "org.freedesktop.UPower.Device")]
public interface Device : Object {

	public abstract void refresh() throws IOError;
	// public abstract void get_history(string type, uint timespan, uint resolution, out ) throws IOError;
	// public abstract void get_statistics() throws IOError;

	public signal void changed();

	public abstract string native_path {owned get;}
	public abstract string vendor {owned get;}
	public abstract string model {owned get;}
	public abstract string serial {owned get;}

	public abstract int64 update_time {get;}
	[DBus (name = "Type")] // we rename type to device_type not to conflict with gobject _get_type() function.
	public abstract uint32 device_type {get;}
	public abstract bool power_supply {get;}
	public abstract bool has_history {get;}
	public abstract bool has_statistics {get;}
	public abstract bool online {get;}

	public abstract double energy {get;}
	public abstract double energy_empty {get;}
	public abstract double energy_full {get;}
	public abstract double energy_full_design {get;}
	public abstract double energy_rate {get;}
	public abstract double voltage {get;}

	public abstract int64 time_to_empty {get;}
	public abstract int64 time_to_full {get;}

	public abstract double percentage {get;}
	public abstract bool is_present {get;}

	public abstract uint32 state {get;}
	public abstract bool is_rechargeable {get;}

	public abstract double capacity {get;}
	public abstract uint32 technology {get;}
	public abstract bool recall_notice {get;}
	public abstract string recall_vendor {owned get;}
	public abstract string recall_url {owned get;}
}

}
