#
# -- root class for URL handlers (formerly named datasources)
#
#
# abstract class defining the common interface for all URL handlers
#


package require Itcl
package require rwconf
package require rwlogger

namespace eval ::rwdatas {

    ::itcl::class UrlHandler {

        private common CURR_URLHANDLER

        private common URLHANDLERS
        private common URLHANDLERS_ARGS
        private common ALIASDB

        set ALIASDB             [dict create]
        set CURR_URLHANDLER     ""
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
        public proc set_handler_arguments {handler args} { 
            dict set URLHANDLERS_ARGS $handler [dict create {*}$args] 
        }
        public proc set_installed_handlers {urlhandlers} { set URLHANDLERS $urlhandlers }
        public proc start_scan {} { return [lindex $URLHANDLERS 0] }
        public proc start_scan_reverse { return [lindex $URLHANDLERS end] }
        private proc search_handler {key returned_key {excluded_handler ""}}
        public proc select_handler {argsqs}
        public proc select_page {argsqs}
        public proc current_handler {}

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
        
        #dict set URLHANDLERS_ARGS $handler $args
        #::rivet::apache_log_error debug "registered handlers $URLHANDLERS"
    }

    # -- next_handler
    #
    #
    #

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
    
    # -- search_handler
    #
    # recusive search of a page through the URL handler list. 
    #

    proc search_handler {key returned_key {excluded_handler ""}} {
        upvar $returned_key rkey

        # this cycle is guaranteed to return a page, al least 
        # through the last datasource in the chain (::RWDummy)

        set handler [::rwdatas::UrlHandler::start_scan]

        while {$handler != ""} {
            if {($handler == $excluded_handler) && ($handler != "::RWDummy")} { 
                ::rivet::apache_log_error debug "excluding $handler from search for $key"
                set handler  [$handler next_handler]
                continue
            }

            ::rivet::apache_log_error info "querying $handler for $key"

            set rkey $key
            if {[$handler will_provide $key rkey]} {
                ::rivet::apache_log_error info \
                    "fetching $key from $handler -> returned values: $rkey"

                set pobj [$handler fetch_page $key rkey]
                if {$pobj != ""} {
                    set CURR_URLHANDLER $handler
                    return              $pobj
                } else {
     
                    if {[string match $key $rkey]} {
                        set rkey wrong_datasource_returned_key
                        return [::RWDummy fetchData $key rkey]
                    }

                    return [search_handler $rkey rkey $handler]
                }

            } else {

                if {($rkey != "") && ($key != $rkey)} {
                    return [search_handler $rkey rkey $handler]
                }

            }
            
            set handler  [$handler next_handler]
        }
        
        return [::RWDummy fetchData page_not_found_error rkey]
    }

    # -- select_handler
    #
    # handler selection driven by the URL arguments
    #
    
    ::itcl::body UrlHandler::select_handler {urlargs} {
        set urlh [::rwdatas::UrlHandler::start_scan]
        set error_info [dict create]
        set page_key ""

        while {$urlh != ""} {

            $::rivetweb::logger log debug [::rivet::xml "querying $urlh" pre]

            set urlquery [catch { $urlh willHandle $urlargs page_key } error_code error_info]
            $::rivetweb::logger log debug "$urlh: urlquery, ecode, einfo: $urlquery | $error_code | $error_info"

            switch $urlquery {

                3 {
                    break
                }
                0 -
                4 {
                    set urlh [$urlh next_handler]
                    continue
                }

            }

        }

        #$::rivetweb::logger log debug "error_code $error_info"
        if {[dict get $error_info -errorcode] == "rw_restart"} {
            $::rivetweb::logger log debug "url handler search forced"
            
            # search_handler sets CURR_URLHANDLER
            
            set ::rivetweb::current_page [::rwdatas::UrlHandler::search_handler $page_key page_key]
        } else {
            #set ::rivetweb::datasource $urlh
            set CURR_URLHANDLER $urlh
        }

        $::rivetweb::logger log info "current handler is $CURR_URLHANDLER"

        return $page_key
    }
    
    # -- current_handler 
    #
    #
    
    ::itcl::body UrlHandler::current_handler {} { return $CURR_URLHANDLER }
    

    # -- select_page
    #
    # Front-end call to retrieve a page.
    #
    #
    
    ::itcl::body UrlHandler::select_page {argsqs} {
        
        set page_key [::rwdatas::UrlHandler::select_handler $argsqs]
        
        $::rivetweb::logger log info "processing request for '$page_key'"

        if {[catch {
                set selected_page [[::rwdatas::UrlHandler::current_handler] fetch_page $page_key page_key]
            } e einfo]} {
            $::rivetweb::logger log err "error: $e ($einfo) "
            set selected_page [::rivetweb simple_page fetch_page_error [::rivetweb make_error_page $e $einfo]]
        }

        set ::rivetweb::page_key $page_key

        return $selected_page
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
                    return [::rwdatas::UrlHandler::search_handler $rkey rkey $this]
                }
            }

            return [$this get_page_object $key]

        } else {

            set p [$this fetchData $key rkey]
            ::rivet::apache_log_error debug "[$this info class]::fetch_page returns $rkey in response of key $key"
            if {$p != ""} {
                $this store_page $key $p
            } else {
                set p [::rwdatas::UrlHandler::search_handler $rkey rkey $this]
            }
            return $p

        }
    }
    
    # -- set_alias
    #
    #

    ::itcl::body UrlHandler::set_alias {alias aliasdef} {
        dict set ALIASDB $alias $aliasdef
    }

    # -- get_alias
    #
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

    # -- to_url
    #
    # basic method that transforms the arguments stored in
    # a link object so that URL specified arguments convert
    # into a form compliant with an application specific 
    # resource definition
    #
    # to the very least the method must return the a link
    # object. Thus, since this is a base class, we return the
    # argument itself

    ::itcl::body UrlHandler::to_url {lm} {
        return $lm
    }

}

package provide UrlHandler 1.0

