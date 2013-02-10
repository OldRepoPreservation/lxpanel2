//      lxpanel2.vala
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

// defined in gtk-run.c
extern void lxpanel_show_run_dialog();

namespace Lxpanel {

static string profile_name;

static const OptionEntry[] option_entries = {
	{"profile", 'p', 0, OptionArg.STRING, ref profile_name, N_("profile name"), null},
	{null}
};


[DBus (name = "org.lxde.Lxpanel")]
public class Application : Object {

	// show "Run" dialog
	public void run() {
		lxpanel_show_run_dialog();
	}
	
	// show application menu, if there is one
	public void menu() {
		foreach(unowned Panel panel in Panel.all_panels) {
			// find an app menu applet and show its menu
			List<weak Applet> applets = panel.get_applets();
			foreach(weak Applet applet in applets) {
				if(applet is AppMenuApplet) {
					AppMenuApplet appmenu = (AppMenuApplet)applet;
					appmenu.popup_menu();
					return;
				}
			}
		}
	}
}

private void init_dbus() {
	// register our dbus service
	Bus.own_name (BusType.SESSION, "org.lxde.Lxpanel", BusNameOwnerFlags.NONE,
		(conn) => { // bus acquired
			try {
				conn.register_object ("/org/lxde/Lxpanel", new Application());
			} catch (IOError e) {
				stderr.printf ("Could not register service\n");
			}
		},
		() => {}, // name acquired
		() => stderr.printf ("Could not aquire name\n"));
}

static void init_unix_signals() {
    Unix.signal_add(Posix.SIGTERM, () => {
        Gtk.main_quit();
        return false;
    });
}

// register built-in applets
private void register_builtin_applets() {
    // register all built-in applets
    AppletInfo info = null;
    info = AppMenuApplet.build_info();
    Applet.register_applet_info(info);

    info = BlankApplet.build_info();
    Applet.register_applet_info(info);

    info = ClockApplet.build_info();
    Applet.register_applet_info(info);

    info = LaunchbarApplet.build_info();
    Applet.register_applet_info(info);

    info = LogoutApplet.build_info();
    Applet.register_applet_info(info);

    info = MountsApplet.build_info();
    Applet.register_applet_info(info);

    info = NetstatusApplet.build_info();
    Applet.register_applet_info(info);

    info = PagerApplet.build_info();
    Applet.register_applet_info(info);

    info = PlacesApplet.build_info();
    Applet.register_applet_info(info);

    info = ShowDesktopApplet.build_info();
    Applet.register_applet_info(info);

    info = SysTrayApplet.build_info();
    Applet.register_applet_info(info);

    info = WnckTaskListApplet.build_info();
    Applet.register_applet_info(info);
}


public int main(string[] args) {

    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

	// var app = new Gtk.Application("org.lxde.Lxpanel", 0);
	Gtk.init_with_args(ref args, _("- lightweight desktop panel"), option_entries, Config.GETTEXT_PACKAGE);
	// var screen = Wnck.Screen.get_default();
	init_dbus();
    init_unix_signals();
	Applet.init(); // initialize applets
    register_builtin_applets();

	if(profile_name == null)
		profile_name = "default";

    // PanelManager.init();
	if(Panel.load_all_panels(profile_name) == false)
		return 1;

	Gtk.main();
	// app.run();
	
	// this should be called by config dialog.
	Panel.save_all_panels(profile_name);
	return 0;
}

}
