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
                set pmodel [$::rivetweb::pmodel create]
                if {$::errorCode == "not_existing"} {
# let's return a conventional page (to be preloaded in the database)

                    $::rivetweb::pmodel put_metadata pmodel                 \
                                        [list   title    "Content not found" \
                                                menu     [list left main]    \
                                                header   "Rivetweb error: content not found"]

                    $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                            "Content for $key not found"

                } else {
# we don't know what to do in this case

		            $::rivetweb::logger log err "Don't know what to do...$e"
                    $::rivetweb::pmodel put_metadata pmodel                 \
                                        [list   title    "Error creating page for key $key" \
                                                menu     [list left main]    \
                                                header   "Error creating page for key $key"]

                    $::rivetweb::pmodel set_pagetext pmodel $::rivetweb::default_lang \
                                                         "Error creating page for key $key"

                }
            } else {
                store $key $pmodel
            }

        } else {
            set pmodel [dict get $sitepages $key]
        }
        return $pmodel
    }
    namespace export fetch

    proc dispose {key} {
        variable sitepages

        if {[check $key]} {
            set pmodel [dict get $sitepages $key]

            $::rivetweb::pmodel dispose $pmodel 

            set sitepages [dict remove $sitepages $key]
        }
    }
    namespace export dispose

    proc erase {} {
        variable sitepages

        foreach k [dict keys $sitepages] {
            set pmodel [dict get $sitepages $k]

            $::rivetweb::pmodel dispose $pmodel
        }
    }
    namespace export erase

    namespace ensemble create
}

package provide rwebdb 0.1
