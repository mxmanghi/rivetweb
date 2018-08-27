#
# -- root class for URL handlers (formerly named datasources)
#
#
# abstract class defining the common interface for all URL handlers
#
#
#

package require Itcl
package require rwconf
package require rwlogger

namespace eval ::rwdatas {

    ::itcl::class UrlHandler {

        private common URLHANDLERS
        private common URLHANDLERS_ARGS
        private common ALIASDB

        set ALIASDB             [dict create]
        set URLHANDLERS         {}
        set URLHANDLERS_ARGS    [dict create ::XMLBase {} ::RWDummy {}]

        private variable scan_context ""

        private variable cache [dict create]

        private method get_page_object { key } 
        public method init {args} { }
        public method destroy {}
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData {key reassigned_key} { return "" }

        ### unimplemented interface (to be removed?)

        public method synchData {key data_dict} {}
        public method createData {key data_dict} {}
        public method storeData {key data_dict} {}

        ###

        public method is_stale {key timereference}
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
        
        public method store_page {key pobj}
        public method clear_cache_entry {key}
        public method cache {} { return $cache }
        public method cache_query { key }
        public method will_provide {keyword reassigned_key}
        public method fetch_page {keyworkd reassigned_key}
        public method signal {notifying_page signal_code}
        public method cleanup {} {}

        public proc register_handler {handler {position top} args}
        public proc registered_handlers {} { return $URLHANDLERS }
        public proc handlers_arguments {} { return $URLHANDLERS_ARGS }
        public proc set_handler_arguments {handler args} { dict set URLHANDLERS_ARGS $handler dict create {*}$args }
        public proc set_installed_handlers {urlhandlers} { set URLHANDLERS $urlhandlers }
        public proc start_scan {} { return [lindex $URLHANDLERS 0] }
        public proc start_scan_reverse { return [lindex $URLHANDLERS end] }
        public method next_handler {}
    }


    # -- destroy
    #
    # application level destruction method
    #
    
    ::itcl::body UrlHandler::destroy { } {

        dict for {key page_o} $cache {
            if {[catch {
                set page [dict get $page_o object]
                $page destroy
            } e opts]} { ::rivet::apache_log_error err "Error deleting page $page ($e)" }
        }

        # specific instance clean up

        $this cleanup 

        ::itcl::delete object $this
    }

    # -- register_handler
    #
    #

    ::itcl::body UrlHandler::register_handler {handler {position top} args} {

        switch $position {
            first -
            top {
                set URLHANDLERS [linsert $URLHANDLERS 0 $handler]
            }
            bottom -
            last -
            default {
                lappend URLHANDLERS $handler
            }
        }
        
        dict set URLHANDLERS_ARGS $handler $args

        ::rivet::apache_log_error notice "registered handlers $URLHANDLERS"
    }

    ::itcl::body UrlHandler::next_handler {} {

        if {$scan_context == ""} {
            set scan_context [lsearch $URLHANDLERS $this]
        }
        ::rivet::apache_log_error debug "next_handler: $this (context: $scan_context)"
        set p $scan_context
        incr p
        if {$p >= [llength $URLHANDLERS]} {

            # in normal operations it shouldn't get 
            # as far as here, as RWDummy is supposed
            # to always respond to some request of data

            return ""
        }

        return [lindex $URLHANDLERS $p]
    }

    # -- is_stale
    #
    # the key is guaranteed to point to an existing page
    # in the cache, as is_stale is called from 'fetch_page'
    # which checks for the existence of this page (otherwise
    # a page object would have been created)
    #
    # This assumption requires the method to be 'private' but
    # it's 'public' instead. TODO
    #

    ::itcl::body UrlHandler::is_stale {key timereference} {

        set page [$this get_page_object $key]
        return [$page refresh $timereference]

    }

    # -- signal
    #
    #

    ::itcl::body UrlHandler::signal {signal_code signal_arg} {

        $::rivetweb::logger log notice "$this signal $signal_code $signal_arg"

        switch $signal_code {

            class_being_deleted {

                # this signal means that the class is already being
                # deleted. we don't need to delete the page instances
                # ourselves, we just remove it from the cache

                set to_be_removed {}

                dict for {key cache_entry} $cache {
                    if {[dict get $cache_entry class] == $signal_arg} {
                        lappend to_be_removed $key
                    }
                }

                foreach k $to_be_removed { $this clear_cache_entry $k }
            }
            page_being_removed {
                $this clear_cache_entry $signal_arg
            }
            page_obj_being_removed {
                $this clear_cache_entry [$signal_arg key]
            }

        }

    }

# -- will_provide
#
#

    ::itcl::body UrlHandler::will_provide {key reassigned_key} {
        upvar $reassigned_key rkey

        set rkey $key
        if {[dict exists $cache $key]} {
            return true
        } else {
            set p [$this fetchData $key rkey]

            if {$p != ""} {
                $this store_page $key $p
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

    ::itcl::body UrlHandler::cache_query {key} {
        return [dict exists $cache $key]
    }

    ::itcl::body UrlHandler::get_page_object {key} {
        return [dict get $cache $key object]
    }
    
# -- store_page
#
#

    ::itcl::body UrlHandler::store_page {key pageobj} {
        dict set cache $key object      $pageobj
        dict set cache $key timestamp   [clock seconds]
        dict set cache $key class       [$pageobj info class]
    }

# -- clear_cache_entry
#
#

    ::itcl::body UrlHandler::clear_cache_entry {key} {
        catch {
            dict unset cache $key
        }
    }

# -- fetch_page
#
#

    ::itcl::body UrlHandler::fetch_page {key reassigned_key} {
        upvar $reassigned_key rkey

        ::rivet::apache_log_error debug "[$this info class] cache '$cache'"
        ::rivet::apache_log_error debug "[$this info class] fetching key '$key'"

        if {[$this cache_query $key]} {
            set rkey $key

            if {[$this is_stale $key [dict get $cache $key timestamp]]} {

                ::rivet::apache_log_error debug "[$this info class]::fetch_page refetching page for $key"

                # is_stale might well delete the entire class thus triggering a 
                # sequence of deletes of its instances. As a matter of fact we 
                # may get here and the object could have already been removed from 
                # the cache

                if {[$this cache_query $key]} {
                    set stored_page [$this get_page_object $key]

                    ### catch added for debugging
                    if {[catch {
                            $this clear_cache_entry $key
                            $stored_page destroy
                        } e opts]} {
                        ::rivet::apache_log_error err \
                        "[$this info class]::fetch_page failed to delete $stored_page. Cache dump"
                        foreach {k page} $cache { ::rivet::apache_log_error err "$k: $page" }
                    }
                }

                set p [$this fetchData $key rkey]
                if {$key == $rkey} {

                    $this store_page $key $p
                    return $p

                } else {
                    return [::rivetweb::search_handler $rkey rkey ::rivetweb::datasource $this]
                }
            }

            return [$this get_page_object $key]

        } else {

            set p [$this fetchData $key rkey]
            ::rivet::apache_log_error debug "[$this info class]::fetch_page returns $rkey in response of key $key"
            if {$p != ""} {
                $this store_page $key $p
            } else {
                set p [::rivetweb::search_handler $rkey rkey ::rivetweb::datasource $this]
            }
            return $p

        }
    }
    
    # -- set_alias
    #

    ::itcl::body UrlHandler::set_alias {alias aliasdef} {
        dict set ALIASDB $alias $aliasdef
    }

    # -- get_alias
    #

    ::itcl::body UrlHandler::get_alias {alias aliasdef} {
        upvar $aliasdef alias_definition

        set alias_found 0
        if {[dict exists $ALIASDB $alias]} {
            set alias_definition [dict get $ALIASDB $alias]
            set alias_found 1
        }

        return $alias_found
    }

    ::itcl::body UrlHandler::to_url {lm} {
        return $lm
    }

}

package provide UrlHandler 1.0

