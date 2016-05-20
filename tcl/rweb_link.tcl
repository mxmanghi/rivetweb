#
# -- rweb_link.tcl
#
# Model for a hypertext link. 
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

    proc create {link_owner reference link_text link_args {link_info ""}} {
        set link_d [dict create owner $link_owner reference $reference]

        ::rivet::apache_log_error debug "<--- $link_text - ($link_info)<br/>"

        foreach l [dict keys $link_text] {
            set l_info ""
            if {$link_info != ""} {
                if {[dict exists $link_info $l]} {
                    set l_info [dict get $link_info $l]
                } 
            }
            add_text link_d $l [dict get $link_text $l] $l_info
        }

# setting arguments dictionary for scripted links

        dict set link_d arguments $link_args

        return $link_d
    }

# -- add_text 
#
# add text and optionally an info for a given language. This method 
# guarantees the default language has a definition (hopefully the
# right one).
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
    namespace export create add_text 

# -- set_attribute, get_attribute: 
# accessors to generic piece of information that should be treated as
# a key-value list to become the attributes of the <a ...> tag

    proc set_attribute {linkobj attribute_list} {
        upvar $linkobj link_o

        foreach {attribute attrvalue} $attribute_list {
            dict set link_o attributes $attribute $attrvalue
        }
    }
    namespace export set_attribute

    proc get_attribute {linkobj attribute} {

        if {[dict exists $linkobj attributes $attribute]} {
            return [dict get $linkobj attributes $attribute]
        } else {
            return ""
        }

    }
    namespace export get_attribute

# -- link_text. accessor for the text to become the
# active part of the link. If 'language' is not specified
# the language will fall back to the default language

    proc link_text {linkmodel {language ""}} {
        if {([string length $language] == 0) || \
            ![dict exists $linkmodel text $language]} {
            set language $::rivetweb::default_lang
        }

        return [dict get $linkmodel text $language]
    }
    namespace export link_text

## -- link_info. The link info is the text to be stored
# in an attribute 'title'. It will show up as popup when
# the cursor hovers on the link. In this implementation
# a dictionary controls the information enabling the storage
# of the information in multiple languages 
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
    namespace export link_info

# -- property
# 
# properties of a link is a free form pair of key-value
# describing a property of a link for internal use of
# a datasource.
# 

    proc property {linkobj property} {
        return [dict get $linkobj $property]
    }
    namespace export property

    proc set_property {linkobj lprop lprop_val} {
        upvar $linkobj link_o

        dict set link_o $lprop $lprop_val
    }
    namespace export set_property

    proc property_exists {linkobj property} {
        return [dict exists $linkobj $property]
    }
    namespace export property_exists

# -- reference. Accessor which returns the hypetext reference
# the link points to. This parameter is set through the 
# set_parameter method

    proc reference {linkobj} {
        return [dict get $linkobj reference]
    }
    namespace export reference

# -- arguments. Returns the arguments dictionary. Arguments
# is list storing key-value pairs to be matched and become
# the part of the URL after the '?' query character joined
# by means of the '&' ampersand char
#

    proc arguments {linkobj} {
        return [dict get $linkobj arguments]
    }
    namespace export arguments

# -- owner
#
    proc owner {linkobj} {
        return [dict get $linkobj owner]
    }
    namespace export owner

# -- urltarget
#
# urltarget link property handling
#
# the 'urltarget' is the suffix appended after
# a '#' char to point to a specific  element within
# a page.
#

    proc set_urltarget {linkobj target} {
        upvar $linkobj lo
        dict set lo urltarget $target
    }
    namespace export set_urltarget

    proc get_urltarget {linkobj target_var} {
        upvar $target_var target

        if {[dict exists $linkobj urltarget]} {
            set target [dict get $linkobj urltarget]
            return true
        } else {
            return false
        }
    }
    namespace export get_urltarget          

    namespace ensemble create
}

package provide rwlink 1.0
