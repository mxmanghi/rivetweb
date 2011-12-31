# -- rweb_coredb.tcl
#
# Rivetweb core db management.
#
#

package require tdom
package require rwconf
package require rwpentry
package require XMLData

namespace eval ::rwebdb {

    variable sitepages [dict create]

    proc check {key} {
        variable sitepages

        return [dict exists $sitepages $key] 
    }
    namespace export check

    proc store {key page_entry} {
        variable sitepages

        dict set sitepages $key $page_entry
    }
    namespace export store

# -- fetch
#
#

    proc fetch {key} {
        variable sitepages

        if {![check $key]} {

            if {[catch {
                set pentry [$::rivetweb::datasource fetchData $key rkey]
            } e]} {
                puts stderr $e
                if {$errorCode == "not_existing"} {
# let's return a conventional page (to be preloaded in the database)


                } else {
# we don't know what to do in this case


                }
            } else {
                store $key $pentry
            }

        } else {
            set pentry [dict get $sitepages $key]
        }
        return $pentry
    }
    namespace export fetch

    proc dispose {key} {
        variable sitepages

        if {[check $key]} {
            set pentry [dict get $sitepages $key]

            $::rivetweb::pentry dispose $pentry 

            set sitepages [dict remove $sitepages $key]
        }
    }
    namespace export dispose

    proc erase {} {
        variable sitepages

        foreach k [dict keys $sitepages] {
            set pentry [dict get $sitepages $k]

            $::rivetweb::pentry dispose $pentry
        }
    }
    namespace export erase

    namespace ensemble create
}

package provide rwebdb 0.1
