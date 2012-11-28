//      gmarkup-dom.vala
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

namespace GMarkupDom {

public class Doc {

	[Flags]
	public enum Flags {
		PRESERVE_SPACE
	}

	public Node root;
	private Flags flags;
    const MarkupParser parser = { // It's a structure, not an object
        parse_start,// when an element opens
        parse_end,  // when an element closes
        parse_text, // when text is found
        null, // when comments are found
        null  // when errors occur
    };
	MarkupParseContext context;
	private unowned Node current_node;

	public Doc() {
	}

	public bool load(string path, Flags flags = 0) {
		this.flags = flags;
		context = new MarkupParseContext(
			parser, // the structure with the callbacks
			0,      // MarkupParseFlags
			this,   // extra argument for the callbacks, methods in this case
			null);
		try {
			string content;
			size_t size;
			FileUtils.get_contents(path, out content, out size);
			return context.parse(content, (ssize_t)size);
		}
		catch(GLib.FileError err) {
		}
		context = null; // release the context
		current_node = null;
		return false;
	}
	
	public string to_string() {
		var buf = new StringBuilder.sized(4096);
		buf.append("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
		root.to_string(ref buf, 0);
		return (owned)buf.str;
	}

	public bool save(string path) {
		string buf = to_string();
		return FileUtils.set_contents(path, buf);
	}

	private void parse_start(MarkupParseContext context,
							string name, 
							string[] attr_names,
							string[] attr_values) throws MarkupError {
		var new_node = new Node(current_node, name, attr_names, attr_values);
		if(current_node != null) {
			// use prepend rather than append for performance reason
			current_node.children.prepend((owned)new_node);
			current_node = current_node.children.first().data;
		}
		else {
			root = (owned)new_node;
			current_node = root;
		}
	}

	private void parse_end(MarkupParseContext context,
							string name) throws MarkupError {
		if(name == current_node.name) { // FIXME: I don't think this is needed
			current_node.children.reverse();
			current_node = current_node.parent;
		}
		else {
			// error!!
		}
	}

	private void parse_text(MarkupParseContext context,
							string text, size_t text_len) throws MarkupError {
		if(current_node != null) {
			if((flags & Flags.PRESERVE_SPACE) != 0) {
				if(current_node.val != null)
					current_node.val += text;
				else
					current_node.val = text;
			}
			else {
				unowned string stripped_text = text._strip();
				if(stripped_text != "") {
					if(current_node.val != null)
						current_node.val += stripped_text;
					else
						current_node.val = stripped_text;
				}
			}
		}
	}
}

public struct Attribute {
	public string name;
	public string val;
}

[Compact]
public class Node {
	public string? name;
	public string? val;
	public unowned Node? parent;
	public GLib.List<Node> children;
	public Attribute[] attributes;

	public Node(Node? parent, string? name, string[] attr_names, string[] attr_values) {
		this.name = name;
		this.parent = parent;
		int len = attr_names.length;
		attributes = new Attribute[len];
		for(int i = 0; i < len; ++i) {
			attributes[i].name = attr_names[i];
			attributes[i].val = attr_values[i];
		}
	}

	// find the first child with the specified name
	public unowned Node? get_child_by_name(string name) {
		foreach(unowned Node child in children) {
			if(child.name == name)
				return child;
		}
		return null;
	}

	public unowned string? get_attribute(string name) {
		foreach(unowned Attribute attribute in attributes) {
			if(attribute.name == name)
				return attribute.val;
		}
		return null;
	}

	public unowned Node new_child(string? name, string? val=null, string[]? attr_names=null, string[]? attr_vals=null) {
		var child = new Node(this, name, attr_names, attr_vals);
		child.val = val;
		unowned Node ret = child;
		children.append((owned)child);
		return ret;
	}

	public void to_string(ref StringBuilder buf, int depth = 0) {
		int i;
		// indent with tabs
		for(i = 0; i < depth; ++i)
			buf.append_c('\t');
		// write open tag
		buf.append_c('<');
		buf.append(name);

		if(attributes != null) { // write attributes
			buf.append_c(' ');
			foreach(unowned Attribute attribute in attributes) {
				buf.append(attribute.name);
				buf.append("=\"");
				buf.append(Markup.escape_text(attribute.val));
				buf.append_c('\"');
			}
		}

		if(val == null && children == null) {
			buf.append(" />\n"); // sometimes a close tag is not needed
			return;
		}

		buf.append_c('>'); // end of open tag

		if(val != null) { // append text data if there're any
			buf.append(val);
		}

		// write child nodes
		if(children != null) {
			buf.append_c('\n'); // we use multiple lines if we have children
			++depth;
			foreach(unowned Node child in children) {
				child.to_string(ref buf, depth);
			}
			--depth;

			// indent with tabs since the close tag is on a new line
			for(i = 0; i < depth; ++i)
				buf.append_c('\t');
		}
		// write close tag
		buf.append("</");
		buf.append(name);
		buf.append(">\n");
	}
}

}
