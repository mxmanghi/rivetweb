#
# -- root class for datasources
#
#
# abstract class defining the common interface for all datasources
#

package require Itcl
package require rwconf
package require rwlogger

namespace eval ::rwdatas {

    ::itcl::class Datasource {

        private variable aliasdb

        public method init {args} { set aliasdb [dict create] }
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData {key reassigned_key}
        public method is_stale {key timereference} { return false }
        public method synchData {key data_dict} {}
        public method dispose {key} {}
        public method has_updates {} { return false }
        public method load_sitemap {sitemap_mgr {ctx ""}}
        public method menu_list {page} { return [dict create] }
        public method name {} { return "Datasource" }
        public method set_alias {alias aliasdef}
        public method get_alias {alias aliasdef}
        public method rewrite_url {rwcode urlscript urlargs rewritten_base}
        public method resource_exists {resource_key {translated_key translated_key}} { return false }
        public method to_url {lm}
    }

    ::itcl::body Datasource::set_alias {alias aliasdef} {
        dict set aliasdb $alias $aliasdef
    }

    ::itcl::body Datasource::get_alias {alias aliasdef} {
        upvar $aliasdef alias_definition

        set alias_found 0
        if {[dict exists $aliasdb $alias]} {
            set alias_definition [dict get $aliasdb $alias]
            set alias_found 1
        }

        return $alias_found
    }

    ::itcl::body Datasource::rewrite_url {rwcode urlscript urlargs rewritten_base} {
        return -code continue -errorcode rw_continue
    }

    ::itcl::body Datasource::to_url {lm} {
        return $lm
    }

}

package provide Datasource 1.0

