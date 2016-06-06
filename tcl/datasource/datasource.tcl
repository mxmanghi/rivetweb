#
# -- root class for datasources
#
#
# abstract class defining the common interface for all datasources
#
#

package require Itcl
package require rwconf
package require rwlogger

namespace eval ::rwdatas {

    ::itcl::class Datasource {

        private common ALIASDB [dict create]

        public method init {args} {  }
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData {key reassigned_key} {}
        public method synchData {key data_dict} {}
        public method createData {key data_dict} {}
        public method storeData {key data_dict} {}
        public method is_stale {key timereference} { return true }
        public method dispose {key} {}
        public method has_updates {} { return false }
        public method load_sitemap {sitemap_mgr {ctx ""}}
        public method menu_list {page} { return [dict create] }
        public method name {} { return [$this info class] }
        public proc   set_alias {alias aliasdef}
        public proc   get_alias {alias aliasdef}
        public method resource_exists {resource_key} { return false }
        public method get_resource_repr {resource_key}  { return "" }
        public proc to_url {lm}
        #public method rewrite_url {rwcode urlscript urlargs rewritten_base}
        public method after_request {} {}
    }

    ::itcl::body Datasource::set_alias {alias aliasdef} {
        dict set ALIASDB $alias $aliasdef
    }

    ::itcl::body Datasource::get_alias {alias aliasdef} {
        upvar $aliasdef alias_definition

        set alias_found 0
        if {[dict exists $ALIASDB $alias]} {
            set alias_definition [dict get $ALIASDB $alias]
            set alias_found 1
        }

        return $alias_found
    }

    ::itcl::body Datasource::to_url {lm} {
        return $lm
    }

#    ::itcl::body Datasource::rewrite_url {rwcode urlscript urlargs rewritten_base} {
#        return -code continue -errorcode rw_continue
#    }

}

package provide Datasource 1.0

