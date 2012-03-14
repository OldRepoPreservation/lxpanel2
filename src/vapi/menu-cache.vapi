// vapi file for libmenu-cache

namespace MenuCache {
   [CCode (cheader_filename = "menu-cache.h", cname ="MenuCache", lower_case_cprefix = "menu_cache_", ref_function = "menu_cache_ref", unref_function = "menu_cache_unref")]
   [Compact]
   public class Cache {
       public void* add_reload_notify (GLib.Func func);
       public uint32 get_desktop_env_flag (string desktop_env);
       public unowned MenuCache.Dir get_dir_from_path (string path);
       public unowned MenuCache.Dir get_root_dir ();
       public static void init (int flags);
       public unowned GLib.SList<App> list_all_apps ();
       public static MenuCache.Cache lookup (string menu_name);
       public static MenuCache.Cache lookup_sync (string menu_name);
       public bool reload ();
       public void remove_reload_notify (void* notify_id);
   }
   [CCode (cheader_filename = "menu-cache.h")]
   [Compact]
   public class App: Item {
       public unowned string get_exec ();
       public bool get_is_visible (uint32 de_flags);
       public uint32 get_show_flags ();
       public bool get_use_sn ();
       public bool get_use_terminal ();
       public unowned string get_working_dir ();
   }
   [CCode (cheader_filename = "menu-cache.h")]
   [Compact]
   public class Dir: Item {
       public unowned GLib.SList<Item> get_children ();
       public unowned string make_path ();
   }

   [CCode (cheader_filename = "menu-cache.h", cname = "MenuCacheType", cprefix="MENU_CACHE_TYPE_")]
   public enum ItemType {
      NONE,
      DIR,
      APP,
      SEP
   }

   [CCode (cheader_filename = "menu-cache.h", ref_function = "menu_cache_item_ref", unref_function = "menu_cache_item_unref")]
   [Compact]
   public class Item {
	   public MenuCache.ItemType get_type();
       public unowned string get_comment ();
       public unowned string get_file_basename ();
       public unowned string get_file_dirname ();
       public unowned string get_file_path ();
       public unowned string get_icon ();
       public unowned string get_id ();
       public unowned string get_name ();
       public unowned MenuCache.Dir get_parent ();
   }
}
