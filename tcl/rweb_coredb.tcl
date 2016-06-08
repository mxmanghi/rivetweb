#
# -- rweb_coredb.tcl
#
# Rivetweb core db management.
# Every page reference is stored in a dictionary whose root key is the
# reference to the page. Each key refers to a second level dictionary
# bearing information
#

package require tdom
package require rwpage

namespace eval ::rwebdb {

    variable sitepages [dict create]

    proc pages {} { 
        variable sitepages

        set pdict [dict create]
        foreach k [dict keys $sitepages] {
            dict set pdict $k [dict get $sitepages $k object]
        }

        return $pdict
    }
    namespace export pages

# -- unset_page
#
# we needed a method to remove a reference to a page object from the
# database. It's responsability of the caller to actually delete the
# page instance.
#

    proc unset_page {key} {
        variable sitepages

        $::rivetweb::logger log debug "Removing page associated to $key"
        catch {dict unset sitepages $key}
    }
    namespace export unset_page

# -- check
#
# Checking if the page associated to the key
# is already in the database
#

    proc check {key} {
        variable sitepages

        return [dict exists $sitepages $key] 
    }
    namespace export check

# -- store
#
# This method stores unconditionally a page model into the in-memory 
# database. The method should evolve to a simple cache mechanism if
# required by the size of the web site.
#

    proc store {key page_model datasource} {
        variable sitepages

# if we are replacing the page object for the key
# we destroy the one had been stored in the database

        if {[dict exists $sitepages $key]} {
            set pobj [dict get $sitepages $key object]
            #puts stderr "deleting $pobj"
            if {[catch {$pobj destroy} e]} {
 
                apache_log_error crit "inconsistent core db entry for key $key ($e)"

            }
        }

        dict set sitepages $key object      $page_model
        dict set sitepages $key timestamp   [clock seconds]
        dict set sitepages $key datasource  $datasource
    }
    namespace export store

# -- is_stale 
#
# is_stale compares the time reference value for the resource
# as returned by the corresponding datasource and the timestamp
# recorded when the resource had been stored in the database.
# if the resource is not found by the datasource then is_stale 
# returns an error, if the resource has no entry in the database
# returns 'true', otherwise returns a boolean value meaning for
# the staleness of the resource.
# 

    proc is_stale {key} {
        variable sitepages

        if {![check $key]} { return true }

        set ts [dict get $sitepages $key timestamp]
        set ds [dict get $sitepages $key datasource]
        return [$ds is_stale $key $ts]

    }
    namespace export is_stale

# -- fetch
#
# central method for rwebdb. The argument 'key' is passed to the
# datasource(s) objects until the resource matching the argument is
# found.
#

    proc fetch {key datasrc} {
        variable sitepages
        upvar $datasrc datasource

        if {[check $key]} {

# page was in the database, we hand it on to the client

            if {[is_stale $key]} {

                $::rivetweb::logger log info \
                        "page for key '$key' is stale, fetching it"
                set pmodel [fetch_from_source $key rkey datasource]
                store $rkey $pmodel $datasource

            } else {

                set pmodel [dict get $sitepages $key object]

            }

        } else {

            set pmodel [fetch_from_source $key rkey datasource]
            store $rkey $pmodel $datasource

        }

        return $pmodel
    }
    namespace export fetch

# -- dispose 
#
# page corresponding to the key argument is removed for 
# the database and method 'dispose' for the page object 
# called.
#
    proc dispose {key} {
        variable sitepages

        if {[check $key]} {
            set pmodel [dict get $sitepages $key object]

            $pmodel destroy

            dict unset sitepages $key
        }
    }
    namespace export dispose


# -- erase
# 
# is a fairly distructive call that empties
# the database after calling the 'dispose' method 
# for each page object
#

    proc erase {} {
        variable sitepages

        foreach k [dict keys $sitepages] {
            set pmodel [dict get $sitepages $k object]

            $pmodel dispose
        }
        
        set sitepages [dict create]
    }
    namespace export erase

# -- fetch_from_source
#
#
#
    proc fetch_from_source {key returned_key datas} {
        variable sitepages
        upvar $datas datasource
        upvar $returned_key rkey

        if {[catch {

            set rkey $key
            set pmodel [$datasource fetchData $key rkey]

            if {$pmodel == ""} {
                if {[string match $key $rkey]} {

                    set rkey wrong_datasource_returned_key
                    set datasource RWDummy

                }
                if {[check $rkey]} {

    # page cache hit

                    if {[is_stale $rkey]} {
                        set pmodel  [fetch_from_source $rkey rkey datasource]
                    } else {
                        set pmodel  [dict get $sitepages $rkey object]
                    }

                } else {

    # this cycle is guaranteed to return a page, al least through datasource ::RWDummy

                    foreach ds $::rivetweb::datasources {
                                          
                        set pmodel [$ds fetchData $rkey returned_key]
                        if {$pmodel != ""} {
                            set rkey        $returned_key
                            set datasource  $ds
                            break
                        }

                    }
                }

            }

        } e]} {

# something else went wrong, it's a rivetweb internal error

            $::rivetweb::logger log err "Rivetweb internal error: $e"

            #set pobj [::rwpage::RWStatic ::#auto internal_error]
            set pobj [::rwpage::RWBasicPage ::#auto rw_internal_error "Error creating page for key '<b>$key</b>'<br /><pre>$e</pre>"]
            store rw_internal_error $pobj ::RWDummy

            #$pobj add_metadata title    "Error creating page for key $key"
            #$pobj add_metadata header   "Error creating page for key $key"
            #$pobj set_pagetext $::rivetweb::default_lang   \
            #                            "Error creating page for key '<b>$key</b>'<br /><pre>$e</pre>"

            set pmodel $pobj

        } 
        return $pmodel
    }

    # -- page
    #
    #

    proc page {key language datasource {txt ""} {header ""} {title ""}} {

        if {[$::rivetweb::rwebdb check $key]} {

            set pobj [$::rivetweb::rwebdb fetch $key $datasource]

        } else {

            set pobj [::rwpage::RWStatic ::#auto $key]
            $::rivetweb::rwebdb store $key $pobj ::RWDummy

        }
        
        if {$txt != ""} {
            $pobj set_pagetext $language $txt
        }
        if {$header != ""} {
            $pobj add_metadata header $header
            $pobj add_metadata title  $header
        }
        if {$title != ""} {
            $pobj add_metadata title  $title
        }

        return $pobj
    }
    namespace export page

    # -- coredump
    #
    #

    proc coredump {} {
        variable sitepages

    # datasource table

        set dstable [::rivet::xml Datasources tr {th colspan 2}]
        foreach ds $::rivetweb::datasources {
            set tbrow "[::rivet::xml $ds td][::rivet::xml [$ds name] td]"
            append dstable [::rivet::xml $tbrow tr]
        }
        set dstable [::rivet::xml $dstable table]

    # page database table

        set row 1
        set html_dump ""
        foreach pageentry [dict keys $sitepages] {

            if {$row == 1} {
                set cell_style [list th style "padding: 0.2em 1em;"]
                foreach prop {page_key object timestamp datasource hits} {
                    append html_dump [::rivet::xml $prop $cell_style]
                }
                set html_dump [::rivet::xml $html_dump tr]
            } 

            set data_row {}
            set cell_style [list td style "padding: 0.2em 1em;"]
            foreach prop {page_key object timestamp datasource hits} {

                set entry_d [dict create {*}[dict get $sitepages $pageentry]]
                switch $prop {

                    page_key {
                        set page [dict get $entry_d object]
                        set urlargs [$page url_args]
                        #puts [list href=[::rivetweb::composeUrl {*}$urlargs] <br/>]
                        append data_row [::rivet::xml $pageentry td [list a href [::rivetweb::composeUrl {*}$urlargs] {*}[lrange $cell_style 1 end]]]
                    }
                    timestamp {
                        set ts [clock format [dict get $entry_d $prop]]
                        append data_row [::rivet::xml $ts $cell_style]
                    }
                    hits {
                        set hits [dict get [$page to_string] hits]
                        append data_row [::rivet::xml $hits $cell_style]
                    }
                    default {
                        append data_row [::rivet::xml [dict get $entry_d $prop] $cell_style]
                    }

                }

            }
            append html_dump [::rivet::xml $data_row tr]
            incr row
        }
        set html_dump [::rivet::xml $html_dump table]

        return [append dstable "\n" $html_dump]
    }
    namespace export coredump

    namespace ensemble create
}

package provide rwebdb 2.0
