//      button.vala
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

public class Button : Gtk.Button, Gtk.Orientable {
	public Button() {
		set_relief(Gtk.ReliefStyle.NONE);
		set_border_width(1);
		show_label = false;
	}

	public void set_icon_pixbuf(Gdk.Pixbuf pix) {
		if(this.pixbuf != pix) {
			this.pixbuf = pix;
			queue_resize();
		}
	}

	public unowned Gdk.Pixbuf? get_icon_pixbuf() {
		return pixbuf;
	}

	public void set_gicon(GLib.Icon icon, int size) {
		if(this.icon != icon) {
			this.icon = icon;
			icon_size = size;
			var info = Gtk.IconTheme.get_default().lookup_by_gicon(icon, size, 0);
			if(info != null)
				set_icon_pixbuf(info.load_icon());
		}
	}

	public unowned GLib.Icon? get_gicon() {
		return icon;
	}

	// resize a themed icon, not effective if gicon is null
	public void set_gicon_size(int size) {
		if(icon_size != size) {
			icon_size = size;

			if(icon != null) {
				// resize icons
				var info = Gtk.IconTheme.get_default().lookup_by_gicon(icon, size, 0);
				if(info != null)
					set_icon_pixbuf(info.load_icon());
			}
		}
	}

	// hide Gtk.Button.set_label
	public new void set_label(string label) {
		base.set_label(label);
		if(show_label == false)
			get_child().hide();
	}

	public void set_show_label(bool show) {
		show_label = show;
		var child = get_child();
		if(child != null) {
			if(show == true)
				child.show();
			else
				child.hide();
		}
	}

	public bool get_show_label(bool show) {
		return show_label;
	}

	// hide & disable Gtk.Button.set_image
	private new void set_image(Gtk.Image image) {		
	}

	// hide & disable Gtk.Button.set_stock
	private new void set_use_stock(bool use_stock) {
	}

	// hide & disable Gtk.Button.set_use_underline
	private new void set_use_underline(bool use_underline) {
	}
	/*
	// hide & disable Gtk.Button.get_label
	private new unowned string get_label() {
		return null;
	}

	// hide & disable Gtk.Button.set_label
	private new void set_label(string label) {
	}
	*/
	protected override void get_preferred_width(out int min, out int natral) {
		min = (int)get_border_width() * 2;
		if(pixbuf != null)
			natral = min + pixbuf.get_width();
		else {
			min += 16;
			natral = min;
		}

		// FIXME: correctly implement this
		/*
		weak Gtk.Widget child = get_child();
		if(child != null) { // label widget
			int child_min, child_natral;
			child.get_preferred_width(out child_min, out child_natral);
			min += child_min + 2;
			natral += child_natral + 2;
		}
		*/
	}

	protected override void get_preferred_height(out int min, out int natral) {
		min = (int)get_border_width() * 2;
		if(pixbuf != null)
			natral = min + pixbuf.get_height();
		else {
			min += 16;
			natral = min;
		}

		// FIXME: correctly implement this
		/*
		weak Gtk.Widget child = get_child();
		if(child != null) { // label widget
			int child_min, child_natral;
			child.get_preferred_height(out child_min, out child_natral);
			min = int.max(min, child_min);
			natral = int.max(min, child_natral);
		}
		*/
	}

	// Gtk.Container.add()
	protected override void add(Gtk.Widget child) {
		if(child is Gtk.Label) {
			child.set_no_show_all(true);
			if(show_label == false)
				child.hide();
		}
		base.add(child);
	}

	protected override void size_allocate(Gtk.Allocation allocation) {
		base.size_allocate(allocation);
		var child = get_child();
		if(child != null && child.get_visible()) {
			int border = (int)get_border_width();
			Gtk.Allocation child_allocation = {
				allocation.x + border,
				allocation.y + border,
				allocation.width - border * 2,
				allocation.height - border * 2
			};

			if(pixbuf != null) {
				int imgw = pixbuf.get_width();
				int imgh = pixbuf.get_height();

				// FIXME: need to handle RTL here
				switch(get_image_position()) {
				case Gtk.PositionType.TOP:
					child_allocation.y += (imgh + 1);
					child_allocation.height -= (imgh - 1);
					break;
				case Gtk.PositionType.LEFT:
					child_allocation.x += (imgw + 1);
					child_allocation.width -= (imgw - 1);
					break;
				case Gtk.PositionType.BOTTOM:
					child_allocation.height -= (imgh + 1);
					break;
				case Gtk.PositionType.RIGHT:
					child_allocation.width -= (imgw + 1);
					break;
				}
			}

			// displace the label for active state
			if((get_state_flags() & Gtk.StateFlags.ACTIVE) != 0) {
				++child_allocation.x;
				++child_allocation.y;
			}
			child.size_allocate(child_allocation);
		}
	}

	protected override bool draw(Cairo.Context cr) {
		var state = get_state_flags();
		cr.save();

		if((state & Gtk.StateFlags.PRELIGHT) != 0) {
			cr.set_source_rgba(1, 1, 1, 0.3);
			cr.fill();
			cr.paint();
		}
		else if((state & Gtk.StateFlags.SELECTED) != 0) {
			var sc = get_style_context();
			Gdk.RGBA bgcolor = sc.get_background_color(state);
			bgcolor.alpha = 0.6;
			Gdk.cairo_set_source_rgba(cr, bgcolor);
			cr.fill();
			cr.paint();
		}

		// FIXME: handle RTL issue here
		if(pixbuf != null) {
			int pix_w = pixbuf.get_width();
			int pix_h = pixbuf.get_height();
			int x = 0, y = 0;

			if(show_label == true) {
				Gtk.PositionType image_pos = get_image_position();
				int border = (int)get_border_width();
				switch(image_pos) {
				case Gtk.PositionType.LEFT:
					x = border;
					y = (get_allocated_height() - pix_h) / 2;
					break;
				case Gtk.PositionType.RIGHT:
					x = get_allocated_width() - pix_w - border;
					y = (get_allocated_height() - pix_h) / 2;
					break;
				}
			}
			else {
				x = (get_allocated_width() - pix_w) / 2;
				y = (get_allocated_height() - pix_h) / 2;
			}

			// stdout.printf("x = %d, y = %d\n", x, y);
			if((state & Gtk.StateFlags.ACTIVE) != 0) {
				// make the image slightly displaced
				++x;
				++y;
			}
			if((state & Gtk.StateFlags.PRELIGHT) != 0) {
				var spotlight = spotlight_pixbuf(pixbuf);
				Gdk.cairo_set_source_pixbuf(cr, spotlight, x, y);
			}
			else {
				Gdk.cairo_set_source_pixbuf(cr, pixbuf, x, y);
			}
			cr.paint();
		}
		cr.restore();

		weak Gtk.Widget child = get_child();
		if(child != null && child.get_visible() == true)
			propagate_draw(child, cr);
		return true;
	}

	// used to position a popup menu
	protected void get_menu_position(Gtk.Widget menu, out int x, out int y, out bool push_in) {
		if(get_realized()) {
			int ox, oy, w, h;
			get_window().get_origin(out ox, out oy);

			Gtk.Requisition req;
			menu.get_preferred_size(null, out req);
			w = req.width;
			h = req.height;
			
			Gtk.Allocation allocation;
			get_allocation(out allocation);
			ox += allocation.x;
			oy += allocation.y;

			if(orientation == Gtk.Orientation.HORIZONTAL) {
				x = ox;
				if (x + w > Gdk.Screen.width())
					x = ox + allocation.width - w;
				y = oy - h;
				if (y < 0)
					y = oy + allocation.height;
			}
			else {
				x = ox + allocation.width;
				if (x > Gdk.Screen.width())
					x = ox - w;
				y = oy;
				if (y + h >  Gdk.Screen.height())
					y = oy + allocation.height - h;
			}
		}
		push_in = true;
	}

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
				queue_resize();
			}
		}
	}

	private Gdk.Pixbuf? pixbuf;
	private GLib.Icon? icon;
	private int icon_size;
	private Gtk.Orientation _orientation;
	private bool show_label;
}

}
