# -- rweb_coredb.tcl
#
# Rivetweb core db management.
#
#

package require tdom
package require rwconf
package require rwpmodel
package require XMLData

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

        dict set sitepages $key $page_model
    }
    namespace export store

# -- fetch
#
#

    proc fetch {key} {
        variable sitepages

        if {![check $key]} {

            if {[catch {

                set pmodel [$::rivetweb::datasource fetchData $key rkey]

            } e]} {

                set error_caught $::errorCode

                set pmodel [$::rivetweb::pmodel create]
                if {$error_caught == "not_existing"} {

# let's return a conventional page (to be preloaded in the database)

                    $::rivetweb::pmodel put_metadata pmodel                 \
                                        [list   title    "Content not found" \
                                                menu     [list left main]    \
                                                header   "Rivetweb error: content not found"]

                    $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                            "Content for $key not found"

                } else {

# something else went wrong, it's a rivetweb internal error

		            $::rivetweb::logger log err "Rivetweb internal error: $error_caught"
                    $::rivetweb::pmodel put_metadata pmodel                 \
                                        [list   title    "Error creating page for key $key ($error_caught)" \
                                                menu     [list left main]    \
                                                header   "Error creating page for key $key"]

                    $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                         "Error creating page for key $key<br /><pre>$e</pre>"

                }
            } else {

# page is stored in the in memory database

                store $key $pmodel
            }

        } else {

# page was in the database, we hand it on to the client

            set pmodel [dict get $sitepages $key]
        }
        return $pmodel
    }
    namespace export fetch

# -- dispose: page corresponding to the key argument
# is removed for the database and method 'dispose' for
# the page object called.

    proc dispose {key} {
        variable sitepages

        if {[check $key]} {
            set pmodel [dict get $sitepages $key]

            $::rivetweb::pmodel dispose $pmodel 

            dict unset sitepages $key
        }
    }
    namespace export dispose


# -- erase is a fairly distructive call that empties
# the database after calling the 'dispose' method 
# for each page object

    proc erase {} {
        variable sitepages

        foreach k [dict keys $sitepages] {
            set pmodel [dict get $sitepages $k]

            $::rivetweb::pmodel dispose $pmodel
        }
        
        set sitepages [dict create]

    }
    namespace export erase

    namespace ensemble create
}

package provide rwebdb 0.1
