[CCode (cname = "Na", cheader_filename = "na-tray.h")]
namespace Na {

	[CCode (cname = "NaTray", cprefix = "na_tray_", has_construct_function=false, cheader_filename = "na-tray.h")]
	public class Tray : Gtk.Bin {
		public Tray.for_screen(Gdk.Screen screen, Gtk.Orientation orientation);
		public void set_orientation(Gtk.Orientation orientation);
		public Gtk.Orientation get_orientation();
		public void set_padding(int padding);
		public void set_icon_size(int icon_size);
		public void set_colors(Gdk.Color fg, Gdk.Color error, Gdk.Color warning, Gdk.Color success);
		public void force_redraw();
		
		public Gdk.Screen screen {get;set construct;}
		public Gtk.Orientation orientation {get;set construct;}
	}

}
