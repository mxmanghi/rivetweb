#
# -- rweb_link.tcl
#
# Model for a hypertext link. 
#
#

package require Itcl
package require rwlogger

namespace eval ::rwlink {

    ::itcl::class RWLink {
        private variable owner
        private variable text
        private variable reference
        private variable target
        private variable arguments
        private variable attributes
        private variable properties
        
        constructor {own lref ltext {largs ""} {linfo ""}} {
            set owner       $own
            set reference   $lref
            set target      ""
            set text        [dict create text [dict create {*}$ltext]] 
           
            if {![dict exists $text text $::rivetweb::default_lang]} {
                return -code error -errcode default_lang_missing "Default language text required for link $lref"
            }

            if {$linfo != ""} { 
                dict set text info [dict create {*}$linfo]
            } else {
                dict set text info [dict create {*}$ltext]
            }
            set arguments $largs
            set attributes [dict create]
            set properties [dict create type generic]
        }

        public method link_owner {} { return $owner }
        public method add_text {language ltext}  { dict set text $language $ltext }
        public method add_info {language linfo}  { dict set info $language $ltext }
        public method set_attributes {attributes_l} {
            set attributes [dict merge $attributes [dict create {*}$attributes_l]]
        }
        public method attribute {attribute} {
            if {[dict exists $attributes $attribute]} {
                return [dict get $attributes $attribute]
            }
            return ""
        }
        public method attributes { } { return $attributes }
        public method link_text {language} {
            if {[dict exists $text text $language]} { 
                return [dict get $text text $language] 
            }
            return [dict get $text text $::rivetweb::default_lang]
        }
        public method link_info {language} {
            if {[dict exists $text info $language]} {
                return [dict get $text info $language]
            } else {
                return ""
            }
        }
        public method property {prop} { return [dict get $properties $prop] }
        public method set_property {prop propv} { dict set properties $prop $propv }
        public method property_exists {prop} { return [dict exists $properties $prop] }
        public method reference {} { return $reference }
        public method arguments {} { return $arguments }
        public method set_target { t } { set target $t }
        public method target {} { return $target }
        public method destroy {} {  ::itcl::delete object $this }
    }


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

        #::rivet::apache_log_error debug "<--- $link_text - ($link_info)<br/>"

        set link_o [RWLink [namespace current]::#auto $link_owner $reference $link_text $link_args $link_info]

        return $link_o
    }
    namespace export create

# -- add_text 
#
# add text and optionally an info for a given language. This method 
# guarantees the default language has a definition (hopefully the
# right one).
#

    proc add_text {linkobj language link_text {link_info ""}} {
        $linkobj add_text $language $link_text
        if {$link_info != ""} { add_info $language $link_info }
    }
    namespace export add_text 

# -- add_info
#
# like add_text but specialized for the dictionary that goes into the info 
# HTML attribute 
#

    proc add_info {linkobj language link_info} {
        $linkobj add_info $language $link_info
    }
    namespace export create add_info


# -- set_attribute, get_attribute: 
# accessors to generic piece of information that should be treated as
# a key-value list to become the attributes of the <a ...> tag

    proc set_attribute {linkobj attribute_list} {
        upvar $linkobj link_obj
    
        $link_obj set_attributes $attribute_list
    }
    namespace export set_attribute

    proc get_attribute {linkobj attribute} {
        return [$linkobj attribute $attribute]
    }
    namespace export get_attribute

    proc attributes {linkobj} {
        return [$linkobj attributes]
    }
    namespace export attributes

# -- link_text. accessor for the text to become the
# active part of the link. If 'language' is not specified
# the language will fall back to the default language

    proc link_text {linkmodel {language ""}} {
        return [$linkmodel link_text $language]
    }
    namespace export link_text

## -- link_info. The link info is the text to be stored
# in an attribute 'title'. It will show up as popup when
# the cursor hovers on the link. In this implementation
# a dictionary controls the information enabling the storage
# of the information in multiple languages 
#

    proc link_info {linkmodel {language ""}} {
        $linkmodel link_info $language
    }
    namespace export link_info

# -- property
# 
# properties of a link is a free form pair of key-value
# describing a property of a link for internal use of
# a datasource.
# 

    proc property {linkobj property} {
        return [$linkobj property $property]
    }
    namespace export property

    proc set_property {linkobj lprop lprop_val} {
        upvar $linkobj link_o

        #::rivet::apache_log_error err "set_property -> $linkobj $lprop $lprop_val"

        $link_o set_property $lprop $lprop_val
   }
    namespace export set_property

    proc property_exists {linkobj property} {
        return [$linkobj property_exists $property]
    }
    namespace export property_exists

# -- reference. Accessor which returns the hypetext reference
# the link points to. This parameter is set through the 
# set_parameter method

    proc reference {linkobj} {
        return [$linkobj reference]
    }
    namespace export reference

# -- arguments. Returns the arguments dictionary. Arguments
# is list storing key-value pairs to be matched and become
# the part of the URL after the '?' query character joined
# by means of the '&' ampersand char
#

    proc arguments {linkobj} {
        return [$linkobj arguments]
    }
    namespace export arguments

# -- owner
#
    proc owner {linkobj} {
        return [$linkobj link_owner]
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
        $lo set_target $target
    }
    namespace export set_urltarget

    proc get_urltarget {linkobj target_var} {
        upvar $target_var target

        set target [$linkobj target]

        return [expr [string length $target] > 0]
    }
    namespace export get_urltarget          

    namespace ensemble create
}

package provide rwlink 2.0
