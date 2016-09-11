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
        private variable cache [dict create]

        public method init {args} {  }
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData {key reassigned_key} { return "" }
        public method synchData {key data_dict} {}
        public method createData {key data_dict} {}
        public method storeData {key data_dict} {}
        public method is_stale {key timereference} { return false }
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

        public method will_provide {keyword reassigned_key}
        public method fetch_page {keyworkd reassigned_key}
    }

# -- will_provide
#
#

    ::itcl::body Datasource::will_provide {key reassigned_key} {
        upvar $reassigned_key rkey

        if {[dict exists $cache $key]} {
            return true
        } else {
            set p [$this fetchData $key rkey]

            if {$p != ""} {
                dict set cache $key object $p
                dict set cache $key timestamp [clock seconds]
                set response true
            } else {
                set response false
            }
            return $response
        }
    }

# -- fetch_page
#
#

    ::itcl::body Datasource::fetch_page {key reassigned_key} {
        upvar $reassigned_key rkey
        ::rivet::apache_log_error info "[namespace current] cache $cache"
        if {[dict exists $cache $key]} {
            set rkey $key

            if {[$this is_stale $key [dict get $cache $key timestamp]]} {
                set stored_page [dict get $cache $key object]
                $stored_page destroy
                set p [$this fetchData $key rkey]
                if {$key == $rkey} {
                    dict set cache $key object $p
                    dict set cache $key timestamp [clock seconds]
                } else {
                    return [::rivetweb::search_datasource $rkey rkey ::rivetweb::datasource]
                }
            }
            return [dict get $cache $key object]

        } else {

            set p [$this fetchData $key rkey]
            if {$p != ""} {
                dict set cache $key object $p
                dict set cache $key timestamp [clock seconds]
            }
            return $p

        }
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

}

package provide Datasource 1.0

