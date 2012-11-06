# -- rweb_coredb.tcl
#
# Rivetweb core db management.
#
#

package require tdom
package require rwconf
package require rwpmodel
#package require XMLData

namespace eval ::rwebdb {

    variable sitepages [dict create]

# -- check
#
# nothing else that checkin if the page associated to the key
# is already in the database
#

    proc check {key} {
        variable sitepages

        return [dict exists $sitepages $key] 
    }
    namespace export check

# -- store
#
# This method stores a page model in the in memory database
# The method should evolve to a simple cache mechanism if
# requested by the size of the web site.
#

    proc store {key page_model} {
        variable sitepages

        dict set sitepages $key object    $page_model
        dict set sitepages $key timestamp [clock seconds]
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
        return [$::rivetweb::datasource is_stale $key $ts]

    }
    namespace export is_stale

# -- fetch
#
# central method for rwebdb. The argument 'key' is passed to the
# datasource(s) objects until the resource matching the argument is
# found.
#

    proc fetch {key} {
        variable sitepages

        if {[check $key]} {

# page was in the database, we hand it on to the client
            if {[is_stale $key]} {
                $::rivetweb::logger log info \
                        "page for key '$key' is stale, fetching it"

                set pmodel [fetch_from_source $key]
            } else {
                set pmodel [dict get $sitepages $key object]
            }

        } else {

            set pmodel [fetch_from_source $key]

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

            $::rivetweb::pmodel dispose $pmodel 

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

            $::rivetweb::pmodel dispose $pmodel
        }
        
        set sitepages [dict create]
    }
    namespace export erase


    proc fetch_from_source {key} {
        variable sitepages

        if {[catch {

            set pmodel [$::rivetweb::datasource fetchData $key rkey]

        } e]} {

            set error_caught $::errorCode

            set pmodel [$::rivetweb::pmodel create]
            if {$error_caught == "not_existing"} {

# let's return a conventional page (to be preloaded in the database)

                $::rivetweb::pmodel put_metadata pmodel                     \
                                    [list   title    "Content not found"    \
                                            menu     [list left main]       \
                                            header   "Rivetweb error: content not found"]

                $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                        "Content for $key not found"

            } else {

# something else went wrong, it's a rivetweb internal error

                $::rivetweb::logger log err "Rivetweb internal error: $error_caught ($e)"
                $::rivetweb::pmodel put_metadata pmodel                     \
                                    [list   title       "Error creating page for key $key ($error_caught)" \
                                            menu        [list left main]    \
                                            header      "Error creating page for key $key"]

                $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                     "Error creating page for key $key<br /><pre>$e</pre>"

            }

        } else {

# page is stored in the in memory database

            store $key $pmodel
        }

        return $pmodel
    }

    namespace ensemble create
}

package provide rwebdb 0.1
