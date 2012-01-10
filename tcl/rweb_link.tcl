#
# -- rweb_link.tcl
#
#
#

package require rwconf
package require rwlogger


namespace eval ::rwlink {

    proc create {link_type reference link_text {link_info ""}} {
        set link_d [dict create type $link_type reference $reference]

        dict set link_d text $link_text
        if {[string length $link_info]} {
            dict set link_d info $link_info
        } 
        return $link_d
    }

    proc add_text {linkmodel language link_text {link_info ""}} {
        upvar $linkmodel linkm

        dict set linkm text $language $link_text
        if {[string length $link_info]} {
            dict set linkm info $language $link_info
        }
    }

    proc ltext {linkmodel language} {
        return [dict get $linkmodel text $language]
    }

    proc linfo {linkmodel language} {
        return [dict get $linkmodel info $language]
    }

    namespace export create add ltext
    namespace ensemble create
}

package provide rwlink 1.0
