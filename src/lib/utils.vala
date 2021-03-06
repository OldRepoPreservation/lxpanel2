//      utils.vala
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

// here are some utilities converting between enum values and strings
// inspired by http://comments.gmane.org/gmane.comp.programming.vala/2129

/*
// parse a string and convert it to an enum value
public int enum_parse_str(Type enum_type, string str) {
	EnumClass klass = (EnumClass)enum_type.class_ref();
	EnumValue? val = klass.get_value_by_name(str);
	return val != null ? val.value : 0;
}
*/

// parse a string and convert it to an enum value
public G enum_nick_parse<G>(string str) {
	EnumClass klass = (EnumClass)typeof(G).class_ref();
	EnumValue? val = klass.get_value_by_nick(str);
	return val != null ? val.value : 0;
}

// parse a string and convert it to an enum value
public G enum_name_parse<G>(string str) {
	EnumClass klass = (EnumClass)typeof(G).class_ref();
	EnumValue? val = klass.get_value_by_name(str);
	return val != null ? val.value : 0;
}

// parse a string and convert it to an enum value
public unowned string enum_to_nick<G>(int enum_val) {
	EnumClass klass = (EnumClass)typeof(G).class_ref();
	EnumValue? val = klass.get_value(enum_val);
	return val != null ? val.value_nick : null;
}

// vala provides .to_string() method for enum values already.

private inline uchar lighten_channel(uchar cur_value)
{
	int new_value = cur_value;
	new_value += 24 + (new_value >> 3);
	if(new_value > 255)
	new_value = 255;
	return (uchar)new_value;
}

public Gdk.Pixbuf? spotlight_pixbuf(Gdk.Pixbuf pix) {
	var width = pix.get_width();
	var height = pix.get_height();
	var has_alpha = pix.get_has_alpha();
	var ret = new Gdk.Pixbuf(pix.get_colorspace(), 
							has_alpha, 
							pix.get_bits_per_sample(), 
							width,
							height);
	var dst_row_stride = ret.get_rowstride();
	var src_row_stride = pix.get_rowstride();

	uint8* dst_pixels = ret.get_pixels();
	uint8* src_pixels = pix.get_pixels();
	for(int i = height; --i >= 0; ) {
		var pixdst = dst_pixels + i * dst_row_stride;
		var pixsrc = src_pixels + i * src_row_stride;
		for(int j = width; j > 0; --j)
		{
			*pixdst++ = lighten_channel(*pixsrc++);
			*pixdst++ = lighten_channel(*pixsrc++);
			*pixdst++ = lighten_channel(*pixsrc++);
			if(has_alpha == true)
				*pixdst++ = *pixsrc++;
		}
	}
	return ret;
}

public void launch_folder(File path, Gdk.Screen? screen) {
    if(screen == null)
        screen = Gdk.Screen.get_default();
    var ctx = new Gdk.AppLaunchContext();
    ctx.set_screen(screen);
    // FIXME: use the file manager specified in lxpanel config file.
    AppInfo.launch_default_for_uri(path.get_uri(), null);
}

public string locate_theme_dir(string theme_name) {
    // search for the user specific themes first
    var theme_dir = Path.build_filename(Environment.get_home_dir(), ".theme", theme_name, "lxpanel", null);
    if(FileUtils.test(theme_dir + "/lxpanel.css", FileTest.IS_REGULAR))
        return theme_dir;

    // try system-wide theme dirs
    var data_dirs = Environment.get_system_data_dirs();
    foreach(unowned string data_dir in data_dirs) {
        theme_dir = Path.build_filename(data_dir, "themes", theme_name, "lxpanel", null);
        if(FileUtils.test(theme_dir + "/lxpanel.css", FileTest.IS_REGULAR))
            return theme_dir;
    }
    return null;
}

// with GtkBuilder + glade, normally, you can only use gtk built-in
// widgets unless you create modules in glade for your custom widgets.
// This function replaces GtkWindow, GtkDialog, or other gtk built-in
// widget with your derived one inside the GtkBuilder xml definition
// and load it. So you can have a derived widget class instead.
public Gtk.Widget? derived_widget_from_gtk_builder(
    string filename, string object_id,
    Type parent_type, Type drived_type, out Gtk.Builder builder) {
    Gtk.Widget widget = null;
    try {
        builder = new Gtk.Builder();
        string xml;
        // load the content of the gtkbuilder ui file into a string first.
        FileUtils.get_contents(filename, out xml);
        // find our target widget, and replace its class name with
        // our derived class

        // FIXME: these string operations are inefficient in vala. Let's optimize it later.
        // replace some xml code, mainly to replace the class name with ours.
        string old_xml = "<object class=\"" + parent_type.name() + "\" id=\"" + object_id + "\">";
        string new_xml = "<object class=\"" + drived_type.name() +"\" id=\"" + object_id + "\">";
        xml = xml.replace(old_xml, new_xml);

        // ask GtkBuilder to load the xml ui definition.
        builder.add_from_string(xml, -1);
        widget = (Gtk.Widget)builder.get_object(object_id);
    }
    catch(Error err) {
        print("%s\n", err.message);
    }
    return widget;
}

}
