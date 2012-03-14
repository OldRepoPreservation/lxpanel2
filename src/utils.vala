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

}
