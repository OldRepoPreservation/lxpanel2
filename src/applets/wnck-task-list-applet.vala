/*
 * wnck-task-list-applet.vala
 * 
 * Copyright (C) 2012 Hong Jen Yee <pcman.tw@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

namespace Lxpanel {

public class WnckTaskListApplet : Applet {

    construct {
        tasklist = new Wnck.Tasklist();
        tasklist.set_button_relief(Gtk.ReliefStyle.NONE);
        tasklist.set_grouping(Wnck.TasklistGroupingType.AUTO_GROUP);
        tasklist.show();
        pack_start(tasklist, false, true, 0);
        set_expand(true);
    }

	public bool load_config(GMarkupDom.Node config_node) {
		foreach(unowned GMarkupDom.Node child in config_node.children) {
			if(child.name == "all_workspace") {
                all_workspace = bool.parse(child.val);
				tasklist.set_include_all_workspaces(all_workspace);
			}
			else if(child.name == "grouping") {
                if(child.val == "auto")
                    grouping = Wnck.TasklistGroupingType.AUTO_GROUP;
                else if(child.val == "never")
                    grouping = Wnck.TasklistGroupingType.NEVER_GROUP;
                else if(child.val == "always")
                    grouping = Wnck.TasklistGroupingType.ALWAYS_GROUP;
                tasklist.set_grouping(grouping);
			}
		}
		return true;
	}

	public void save_config(GMarkupDom.Node config_node) {
        config_node.new_child("all_workspace", all_workspace.to_string());
        config_node.new_child("grouping", enum_to_nick<Wnck.TasklistGroupingType>(grouping));
	}

    protected override void get_preferred_width(out int min, out int natural) {
        // NOTE:
        // WnckTaskList calls size_request() in get_preferred_width() and
        // get_preferred_height() internally and re-layout the widget
        // within size_request(). So its height changes after
        // get_preferred_width() is called, and width may change after
        // get_preferred_height() is called. This behavior is really bad.
        // if we don't chain up to base class here, layout of the task bar
        // can be incorrect. However, I noticed that we need to override
        // WnckTaskList and return very small values here. Otherwise,
        // its tasklist will becomes very large, and go outside the screen.
        base.get_preferred_width(out min, out natural);
        // NOTE: we tried to set the preferred size as small as possible
        // to overcome problems of libwnck.
        min = natural = 2;
    }

    protected override void get_preferred_height(out int min, out int natural) {
        // See the comment in get_preferred_width().
        base.get_preferred_width(out min, out natural);
        min = natural = 2;
    }

	internal static AppletInfo build_info() {
        AppletInfo applet_info = new AppletInfo();
        applet_info.type_id = typeof(WnckTaskListApplet);
		applet_info.type_name = "wncktasklist";
		applet_info.name= _("Tasklist");
		applet_info.description= _("Tasklist");
        return (owned)applet_info;
	}

    Wnck.Tasklist tasklist;
    bool all_workspace = false;
    Wnck.TasklistGroupingType grouping = Wnck.TasklistGroupingType.AUTO_GROUP;
}

}

