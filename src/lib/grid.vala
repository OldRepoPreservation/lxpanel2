//      grid.vala
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

public class Grid : Gtk.Container, Gtk.Orientable {

    public Grid() {
		scroll_bar = new Gtk.Scrollbar(Gtk.Orientation.VERTICAL, null);
		scroll_bar.set_parent(this);
		scroll_bar.show_all();
    }

    ~Grid() {
    }

    public void set_cell_size(int width, int height, queue_resize = true) {
        if(width != -1)
            cell_width = width;
        if(height != -1)
            cell_height = height;

        if(queue_resize == true)
            this.queue_resize();
    }

    public int get_cell_width() {
        return cell_width;
    }

    public int get_cell_height() {
        return cell_height;
    }

    public int get_scrollbar_size() {
        int size;
        if(_orientation == Gtk.Orientation.HORIZONTAL)
            scroll_bar.get_preferred_width(null, out size);
        else
            scroll_bar.get_preferred_height(null, out size);
        return size;
    }

    public int get_n_rows() {
        return n_rows;
    }
    
    public int get_n_cols() {
        return n_cols;
    }

	protected override void size_allocate(Gtk.Allocation allocation) {
        // base.size_allocate(allocation);
		set_allocation(allocation);

        uint n_children = children.get_length();
        n_cols = allocation.width / cell_width;
        n_rows = n_children / n_cols;
        if(n_children % n_cols)
            ++n_rows;
        int rows_per_page = allocation.height / cell_height;
        if(rows_per_page < n_rows) {
            // scrollbar is needed.
            gtk_widget_show(scroll_bar); // show the scroll bar
            // put it at right border of the grid
            Gtk.Allocation scroll_bar_alloc = allocation;
            scroll_bar.get_preferred_width(null, out scroll_bar_alloc.width);
            scroll_bar_alloc.x += allocation.width - scroll_bar_alloc.width;
            scroll_bar.size_allocate(scroll_bar_alloc);

            n_cols = (allocation.width - get_scrollbar_size()) / cell_width;
            n_rows = n_children / n_cols;
            if(n_children % n_cols)
                ++n_rows;
        }

        

/*
		if(show_label) { // if we show labels, the applet needs to be expandable
			// if the task list is expanded to fill all available spaces
			if(children != null) {
				// FIXME: handle vertical orientation
				Gtk.Allocation child_allocation = {0};
				int n_rows = int.max(1, allocation.height / btn_height);
				int n_children = (int)children.length();
				int n_cols = n_children / n_rows;
				if(n_children % n_rows != 0)
					++n_cols;
				int btn_size = allocation.width / n_cols;
				// btn_size.clamp(min_btn_size, max_btn_size);
				btn_size = int.min(max_btn_size, btn_size);
				child_allocation.x = allocation.x;
				child_allocation.y = allocation.y;
				child_allocation.width = btn_size;
				child_allocation.height = btn_height;
				int row = 1;
				foreach(weak Gtk.Widget child in children) {
					if(!child.get_visible())
						continue;
					child.size_allocate(child_allocation);
					if(row < n_rows) {
						child_allocation.y += btn_height;
						++row;
					}
					else {
						child_allocation.y = allocation.y;
						row = 1;
						child_allocation.x += btn_size;
					}
				}
			}
		}
		else { // icon only
			if(children != null) {
				Gtk.Allocation child_allocation = allocation;
				if(get_orientation() == Gtk.Orientation.HORIZONTAL) {
				}
				else { // vertical
					// FIXME: implement this
				}
			}
		}
*/
	}

	// for Gtk.Orientable iface
	public Gtk.Orientation orientation {
		get {	return _orientation;	}
		set {
			if(_orientation != value) {
				_orientation = value;
				set_orientation(value);
			}
		}
	}

	public void insert_child(Gtk.Widget child, int index) {
		children.insert(child, index);
		child.set_parent(this);
        queue_resize();
	}

	// Gtk.Container
	public override void add(Gtk.Widget child) {
		insert_child(child, -1);
	}
	
	public override void remove(Gtk.Widget child) {
		unowned List<Gtk.Widget> link = children.find(child);
		if(link != null) {
			if(child.get_visible() && get_visible())
				queue_resize();
			children.delete_link(link);
			child.unparent();
		}
        queue_resize();
	}

	public override void forall(Gtk.Callback callback) {
		foreach(weak Gtk.Widget child in children) {
			callback(child);
		}
	}

	public override void forall_internal(bool include_internal, Gtk.Callback callback) {
        // for non-internal children
		foreach(weak Gtk.Widget child in children) {
			callback(child);
		}

        // for internal children
        callback(scroll_bar);
	}

    private int cell_width;
    private int cell_height;

    private int n_cols;
    private int n_rows;

	private Gtk.Scrollbar scroll_bar;

	// for Gtk.Container child widgets
	protected List<Gtk.Widget> children;

    // for GtkOrientable
	private Gtk.Orientation _orientation;
}

}
