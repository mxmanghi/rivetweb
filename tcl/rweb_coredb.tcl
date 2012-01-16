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

    proc check {key} {
        variable sitepages

        return [dict exists $sitepages $key] 
    }
    namespace export check

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
                if {$::errorCode == "not_existing"} {
# let's return a conventional page (to be preloaded in the database)

                    set pmodel [$::rivetweb::pmodel create]
                    $::rivetweb::pmodel put_metadata pmodel                 \
                                        [list   title    "Content not found" \
                                                menu     [list left main]    \
                                                header   "Rivetweb error: content not found"]

                    set error_page_dom [dom createDocument div]
                    set error_page_o   [$error_page_dom documentElement]
                    set error_message_o  [$error_page_dom createTextNode "Content for $key not found"]
                    $error_page_dom appendChild $error_message_o

                    $::rivetweb::pmodel add_content pmodel $::rivetweb::default_lang \
                                                    pagetext $error_page_dom


                } else {
# we don't know what to do in this case

		    $::rivetweb::logger log err "Don't know what to do...$e"

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
