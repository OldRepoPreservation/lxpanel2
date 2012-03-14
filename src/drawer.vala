//      drawer.vala
//      
//      Copyright 2011-2012 Hong Jen Yee (PCMan) <pcman.tw@gmail.com>
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

public class Drawer : Button {

	public Drawer() {
		popup = new Popup();
	}

	unowned Popup? get_popup() {
		return popup;
	}

	protected override void clicked() {
		if(popup != null) {
			popup.popup(get_menu_position, 1, Gtk.get_current_event_time());
		}
	}

	protected Popup? popup;
}

}
