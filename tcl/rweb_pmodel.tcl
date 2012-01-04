# -- rweb_pmodel.tcl
#
# we try to hide as much as possible the page model implementation
#
#

package require tdom
package require rwlogger
package require rwconf

namespace eval ::rwpmodel {

    proc create {} {
        return [dict create]
    }

    proc add_metadata {pmodel field value} {
        upvar $pmodel page_model

        dict set page_model metadata $field $value
    }

    proc set_metadata {pmodel mdlist} {
        upvar $pmodel page_model

        dict set page_model metadata [eval dict create $mdlist]
    }

    proc put_metadata {pmodel dictionary} {
        upvar $pmodel page_model
        
        foreach k [dict keys $dictionary] {
            dict set page_model metadata $k [dict get $dictionary $k]
        }
    }

    proc add_content {pmodel language field value} {
        upvar $pmodel page_model

        dict set page_model content $language $field $value
        if {![dict exists $page_model content $::rivetweb::default_lang $field]} {
            dict set page_model content $::rivetweb::default_lang $field $value
        }
    }

    proc content { pmodel language } {
        if {[dict exists $pmodel content $language]} {
            return [dict get $pmodel content $language]
        } elseif {[dict exists $pmodel content $::rivetweb::default_lang]} {
            return [dict get $pmodel content $::rivetweb::default_lang]
        } else {
            set errormsg "Inconsistent model: Missing data for default language"

            $::rivetweb::logger log emerg "inconsistent model: $pmodel"

            return -code error  -errorcode missing_default_content  \
                                -errorinfo $errormsg $errormsg
        }
    }

    proc metadata { pmodel } {

        return [dict get $pmodel metadata]

    }

    proc mdmodel { pmodel field } {
        if {[dict exists $pmodel metadata $field]} {
            return [dict get $pmodel metadata $field]
        } else {
#           puts "$pmodel: $field"
            return ""
        }
#        if {[catch {
#            return [dict get $pmodel metadata $field]
#        }]} {
#            $::rivetweb::logger log emerg "wrong model structure? ($pmodel)"
#            return -code error
#        }
    }

    proc dispose { pmodel } {
            
        foreach {language v} [dict get $pmodel content] {
            set pagedom [dict get $pmodel content $language pagetext]
            $pagedom delete
        }

    }
    namespace export *
    namespace ensemble create
}

package provide rwpmodel 0.1
