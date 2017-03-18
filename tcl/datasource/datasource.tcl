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
        public method destroy {}
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
        public method to_url {lm}
        #public method rewrite_url {rwcode urlscript urlargs rewritten_base}
        public method after_request {} {}

        public method cache {} { return $cache }
        public method cache_query { key }
        public method will_provide {keyword reassigned_key}
        public method fetch_page {keyworkd reassigned_key}

    }

    ::itcl::body Datasource::destroy { } {

        dict for {key page_o} $cache {
            if {[catch {
                set page [dict get $page_o object]
                $page destroy
            } e opts]} {
                ::rivet::apache_log_error err "Error deleting page $page ($e)"
            }
        }

        ::itcl::delete object $this
    }


# -- will_provide
#
#

    ::itcl::body Datasource::will_provide {key reassigned_key} {
        upvar $reassigned_key rkey

        set rkey $key
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

# -- cache_query
#
#

    ::itcl::body Datasource::cache_query {key} {

        return [dict exists $cache $key]

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

                ### catch added for debugging
                if {[catch {$stored_page destroy} e opts]} {
                    ::rivet::apache_log_error err "failed to delete $stored_page. Cache dump"
                    foreach {k page} $cache { ::rivet::apache_log_error err "$k: $page" }
                }

                set p [$this fetchData $key rkey]
                if {$key == $rkey} {
                    dict set cache $key object $p
                    dict set cache $key timestamp [clock seconds]
                } else {
                    return [::rivetweb::search_datasources $rkey rkey ::rivetweb::datasource]
                }
            }
            return [dict get $cache $key object]

        } else {

            set p [$this fetchData $key rkey]
            if {$p != ""} {
                dict set cache $key object $p
                dict set cache $key timestamp [clock seconds]
            } else {
                set p [::rivetweb::search_datasources $rkey rkey ::rivetweb::datasource]
                #if {$key != $rkey} {
                #    set p [::rivetweb::search_datasources $rkey rkey ::rivetweb::datasource]
                #} else {
                #    set ::rivetweb::datasource ::RWDummy 
                #
                #    set p [::RWDummy fetchData wrong_datasource_returned_key rkey]
                #}
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

