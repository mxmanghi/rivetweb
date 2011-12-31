# -- rweb_pentry.tcl
#
# we try to hide as much as possible the page entry implementation
#
#

package require tdom
package require rwlogger
package require rwconf

namespace eval ::rwpentry {

    proc create {} {
        return [dict create]
    }

    proc add_metadata {pentry field value} {
        upvar $pentry page_entry

        dict set page_entry metadata $field $value
    }

    proc set_metadata {pentry mdlist} {
        upvar $pentry page_entry

        dict set page_entry metadata [eval dict create $mdlist]
    }

    proc put_metadata {pentry dictionary} {
        upvar $pentry page_entry
        
        foreach k [dict keys $dictionary] {
            dict set page_entry metadata $k [dict get $dictionary $k]
        }
    }

    proc add_content {pentry language field value} {
        upvar $pentry page_entry

        dict set page_entry content $language $field $value
        if {![dict exists $page_entry content $::rivetweb::default_lang $field]} {
            dict set page_entry content $::rivetweb::default_lang $field $value
        }
    }

    proc content { pentry language } {
        if {[dict exists $pentry content $language]} {
            return [dict get $pentry content $language]
        } elseif {[dict exists $pentry content $::rivetweb::default_lang]} {
            return [dict get $pentry content $::rivetweb::default_lang]
        } else {
            set errormsg "Inconsistent entry: Missing data for default language"

            $::rivetweb::logger log emerg "inconsistent entry: $pentry"

            return -code error  -errorcode missing_default_content  \
                                -errorinfo $errormsg $errormsg
        }
    }

    proc metadata { pentry } {

        return [dict get $pentry metadata]

    }

    proc mdentry { pentry field } {
        if {[dict exists $pentry metadata $field]} {
            return [dict get $pentry metadata $field]
        } else {
#           puts "$pentry: $field"
            return ""
        }
#        if {[catch {
#            return [dict get $pentry metadata $field]
#        }]} {
#            $::rivetweb::logger log emerg "wrong entry structure? ($pentry)"
#            return -code error
#        }
    }

    proc dispose { pentry } {
            
        foreach {language v} [dict get $pentry content] {
            set pagedom [dict get $pentry content $language pagetext]
            $pagedom delete
        }

    }
    namespace export *
    namespace ensemble create
}

package provide rwpentry 0.1
