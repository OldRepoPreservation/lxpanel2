
namespace Lxpanel {

const string DEFAULT_TIP_FORMAT = "%A %x";
const string DEFAULT_CLOCK_FORMAT = "%R";

public class ClockApplet : Applet {

	construct {
        label = new Gtk.Label("");
        pack_start(label, false, true, 0);
        label.show();
		timeout = Timeout.add(1000, on_timeout);
		on_timeout();
	}

	protected override void dispose() {
		if(timeout != 0) {
			Source.remove(timeout);
			timeout = 0;
		}
        base.dispose();
	}

    /*
    protected override bool button_press_event(Gdk.EventButton evt) {
        var popup = new Popup();
        popup.ref();
        var calendar = new Gtk.Calendar();
        calendar.show();
        popup.add(calendar);
        popup.popup(null, evt.button, evt.time);
        return true;
    }
    */

	private bool on_timeout() {
		var _time = time_t();
		Time local_time = Time.local(_time);
		var text = local_time.format(DEFAULT_CLOCK_FORMAT);
		label.set_label(text);
		return true;
	}

	public static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(ClockApplet);
		applet_info.type_name = "clock";
		applet_info.name= _("Clock");
		applet_info.description= _("Clock");
        return (owned)applet_info;
	}

	private uint timeout;
    Gtk.Label label;
}

}
