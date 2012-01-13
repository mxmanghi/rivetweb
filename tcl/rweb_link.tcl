#
# -- rweb_link.tcl
#
#
#

package require rwconf
package require rwlogger


namespace eval ::rwlink {

# -- create
#
# constructor method of a link object. Notice that link_text and link_info
# when passed to this method must be dictionaries in the form 
#
#  <lang1> -> <text lang1>
#  <lang2> -> <text lang2>
#  .... 
#

    proc create {link_type reference link_text {link_info ""}} {
        set link_d [dict create type $link_type reference $reference]

        dict set link_d text $link_text
        if {[string length $link_info]} {
            dict set link_d info $link_info
        } 
        return $link_d
    }

# -- add_text 
#
# add text and info for a specific language
#
#

    proc add_text {linkmodel language link_text {link_info ""}} {
        upvar $linkmodel linkm

        dict set linkm text $language $link_text

# we just make sure we have a value for the default language

        if {![dict exists $linkm text $::rivetweb::default_lang]} {
            dict set linkm text $::rivetweb::default_lang $link_text
        }

        if {[string length $link_info]} {
            dict set linkm info $language $link_info
            
            if {![dict exists $linkm info $::rivetweb::default_lang]} {
                dict set linkm info $::rivetweb::default_lang $link_info
            }
        }

    }

    proc link_text {linkmodel {language ""}} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        }
        return [dict get $linkmodel text $language]
    }

    proc link_info {linkmodel {language ""}} {
        if {[string length $language] == 0} {
            return [dict get $linkmodel info $language]
        }
    }

    namespace export create add link_text link_info
    namespace ensemble create
}

package provide rwlink 1.0
