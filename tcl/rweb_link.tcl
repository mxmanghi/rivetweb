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

    proc set_attribute {linkobj attribute_list} {
        upvar $linkobj link_o

        foreach {attribute attrvalue} $attribute_list {
            dict set link_o attributes $attribute $attrvalue
        }
    }

    proc get_attribute {linkobj attribute} {

        if {[dict exists $linkobj attributes $attribute]} {
            return [dict get $linkobj attributes $attribute]
        } else {
            return ""
        }

    }

    proc link_text {linkmodel {language ""}} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        }
        return [dict get $linkmodel text $language]
    }

    proc reference {linkobj} {
        return [dict get $linkobj reference]
    }


## -- link_info
#
#
#

    proc link_info {linkmodel {language ""}} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        } 

        if {[dict exists $linkmodel info $language]} {
            return [dict get $linkmodel info $language]
        } else {
            return ""
        }
    }

    proc type {linkmodel} {
        return [dict get $linkmodel type]
    }

    namespace export create add link_text link_info reference type \
                     set_attribute get_attribute 
    namespace ensemble create
}

package provide rwlink 1.0
