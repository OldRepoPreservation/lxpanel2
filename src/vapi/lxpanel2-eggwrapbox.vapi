[CCode (cprefix = "Egg", lower_case_cprefix = "egg_", cheader_filename = "eggwrapbox.h")]
namespace Egg {

	[CCode (cheader_filename = "eggwrapbox.h", cprefix = "EGG_WRAP_ALLOCATE_")]
	public enum WrapAllocationMode {
		FREE = 0,
		ALIGNED,
		HOMOGENEOUS
	}

	[CCode (cheader_filename = "eggwrapbox.h", cprefix = "EGG_WRAP_BOX_SPREAD_")]
	public enum WrapBoxSpreading {
		START = 0,
		END,
		EVEN,
		EXPAND
	}

	[CCode (cheader_filename = "eggwrapbox.h", cprefix = "EGG_WRAP_BOX_")]
	public enum WrapBoxPacking {
		H_EXPAND = 1 << 0,
		V_EXPAND = 1 << 1
	}

	[CCode (cheader_filename = "eggwrapbox.h")]
	public class WrapBox : Gtk.Container {
		[CCode (has_construct_function = false, type = "GtkWidget*")]
		public WrapBox(WrapAllocationMode mode,
						WrapBoxSpreading horizontal_spreading,
						WrapBoxSpreading vertical_spreading,
						uint horizontal_spacing,
						uint vertical_spacing);
		
		public void set_allocation_mode(WrapAllocationMode mode);
		public WrapAllocationMode get_allocation_mode();
		public void set_horizontal_spreading(WrapBoxSpreading spreading);
		public WrapBoxSpreading get_horizontal_spreading();

		public void set_vertical_spreading(WrapBoxSpreading spreading);
		public WrapBoxSpreading get_vertical_spreading();
		public void set_vertical_spacing(uint spacing);
		public uint get_vertical_spacing();

		public void set_horizontal_spacing(uint spacing);
		public uint get_horizontal_spacing();

		public void set_minimum_line_children(uint n_children);
		public uint get_minimum_line_children();

		public void set_natural_line_children(uint n_children);
		public uint get_natural_line_children();

		public void insert_child(Gtk.Widget widget, int index, WrapBoxPacking packing);
		public void reorder_child(Gtk.Widget widget, uint index);
	}
}

