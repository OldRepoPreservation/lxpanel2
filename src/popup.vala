//      popup.vala
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

// popup window used as menu, mainly used with Drawer
public class Popup : Gtk.Window {
	public Popup() {
		Object(type: Gtk.WindowType.POPUP);
		set_type_hint(Gdk.WindowTypeHint.POPUP_MENU);
	}

	protected override bool map_event(Gdk.EventAny evt) {
		debug("show");
		return base.map_event(evt);
	}

	protected override bool button_press_event(Gdk.EventButton evt) {
		popdown();
		hide();
		debug("hide");
		return base.button_press_event(evt);
	}

	public void popup_for_device(Gdk.Device device, Gtk.MenuPositionFunc func, uint button, uint32 time) {
		show(); // need to show the window first since non-visible window cannot do grab

		grab_focus(); // grab keyboard focus

		// try to grab all keyboard/mouse event
		// need to find out the right device to grab first
		unowned Gdk.Device? keyboard, pointer;
		if(device.get_source() == Gdk.InputSource.KEYBOARD) {
			keyboard = device;
			pointer = device.get_associated_device();
		}
		else {
			pointer = device;
			keyboard = device.get_associated_device();
		}
		grab_pointer = pointer;
		grab_keyboard = keyboard;

		// grab all keyboard/mouse events for the underlying gdk window
		// grab the mouse pointer for the window
		if(pointer.grab(get_window(),
			Gdk.GrabOwnership.WINDOW, true,
			Gdk.EventMask.BUTTON_PRESS_MASK|Gdk.EventMask.BUTTON_RELEASE_MASK|
			Gdk.EventMask.POINTER_MOTION_MASK, null, time) != Gdk.GrabStatus.SUCCESS) {
			debug("failure1");
			Gtk.device_grab_remove(this, pointer);
			hide();
			return;
		}

		// grab the keyboard for the window
		if(keyboard.grab(get_window(),
			Gdk.GrabOwnership.WINDOW, true,
			Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK,
			null, time) != Gdk.GrabStatus.SUCCESS) {
			debug("failure2");
			pointer.ungrab(time);
			Gtk.device_grab_remove(this, pointer);
			hide();
			return;
		}

		// grab all mouse event for this gtk widget
		Gtk.device_grab_add(this, pointer, true);

		int x, y;
		bool push_in;
		// no type safety here :(
		func((Gtk.Menu)this, out x, out y, out push_in);
		move(x, y);
		present();
	}
	
	public void popup(Gtk.MenuPositionFunc func, uint button, uint32 activate_time) {
		Gdk.Device device = Gtk.get_current_event_device();
		if(device == null) {
			Gdk.Display display = get_display();
			Gdk.DeviceManager device_manager = display.get_device_manager();

			// FIXME: vapi for gdk-3.0 incorrectly marks this returned list as unowned.
			// Actually, it's a newly allocated list which nees to be freed.
			// This caused a memory leak here.
			// We have to file a bug report in vala for this.
			unowned List<weak Gdk.Device> devices = device_manager.list_devices(Gdk.DeviceType.MASTER);
			device = devices.data;
		}
		popup_for_device(device, func, button, activate_time);
	}
	
	public void popdown() {
		if(grab_pointer != null) {
			grab_keyboard.ungrab(Gdk.CURRENT_TIME);
			grab_pointer.ungrab(Gdk.CURRENT_TIME);

			Gtk.device_grab_remove(this, grab_pointer);
			grab_pointer = null;
			grab_keyboard = null;
		}
		hide();
	}

	protected override bool draw(Cairo.Context cr) {
		var sc = get_style_context();

		sc.save(); // use the style of a menu to paint this window
		sc.add_class(Gtk.STYLE_CLASS_MENU);

		cr.save();
		Gtk.render_background(sc, cr, 0, 0, get_allocated_width(), get_allocated_height());
		Gtk.render_frame(sc, cr, 0, 0, get_allocated_width(), get_allocated_height());
		cr.restore();
		
		sc.restore();
		propagate_draw(get_child(), cr);
		//base.draw(cr);
		return true;
	}
	
	private weak Gdk.Device? grab_pointer;
	private weak Gdk.Device? grab_keyboard;
}

}
