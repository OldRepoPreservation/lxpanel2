
namespace Lxpanel {

const string DEFAULT_TIP_FORMAT = "%A %x";
const string DEFAULT_CLOCK_FORMAT = "%R";

public class ClockApplet : Gtk.Label, Applet {

	public ClockApplet(Panel panel) {
		timeout = Timeout.add(1000, on_timeout);
		on_timeout();

		// Gdk.RGBA color = {1, 0, 0, 1};
		// override_color(Gtk.StateFlags.NORMAL, color);

		// set text color/font
		unowned Pango.AttrList attrs = panel.get_text_attrs();
		if(attrs != null)
			set_attributes(attrs);
	}

	protected override void dispose() {
		if(timeout != 0) {
			Source.remove(timeout);
			timeout = 0;
		}
	}

	private bool on_timeout() {
		var _time = time_t();
		Time local_time = Time.local(_time);
		var text = local_time.format(DEFAULT_CLOCK_FORMAT);
		set_label(text);
		return true;
	}

	public unowned Applet.Info? get_info() {
		return applet_info;
	}

	public static void register() {
		applet_info.type_name = "clock";
		applet_info.name= _("Clock");
		applet_info.description= _("Clock");
		applet_info.author= _("Lxpanel");
		applet_info.create_applet=(panel) => {
			var applet = new ClockApplet(panel);
			return applet;
		};
		Applet.register(ref applet_info);
	}
	public static Applet.Info  applet_info;

	private uint timeout;
}

}
