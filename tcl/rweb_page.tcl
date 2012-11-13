#
# -- rweb_page.tcl
#
# base class for every page model providing for base
# methods and common interface to every other page model
#

package require Itcl

namespace eval ::rwpage {

    ::itcl::class RWPage {
        private variable content
        private variable metadata
        private variable key

        constructor {pagekey} {
            set key $pagekey
            set metadata [dict create]
            set content [dict create]
        }

        public method key {} { return $key }
        public method add_metadata {field value} 
        public method set_metadata {mdlist}
        public method put_metadata {dictionary} 
        public method set_content {language field value} 
        public method content {language {fmt -reference}} 
        public method languages { } 
        public method metadata {{key ""}}
        public method dispose { }
    }

# -- add_metadata 
#
# method to store in a page instance the metadata associated
# with the keyword 'field' and whose value is 'value'
#
#
    ::itcl::body RWPage::add_metadata {field value} {
        dict set metadata $field $value
    }

# -- set_metadata
#
# the list 'mdlist' is treated as a even length list to be interpreted
# as a sequence of keyword-value pairs. The keywords are assembled and 
# become the new metadata of the instance 'pageobj' erasing metadata 
# that could have been defined beforehand  

    ::itcl::body RWPage::set_metadata {mdlist} {
        dict set metadata [eval dict create $mdlist]
    }

# -- put_metadata 
# 
# metadata dictionary is replaced by the <dictionary> value
# 

    ::itcl::body RWPage::put_metadata {dictionary} {
 
        set metadata $dictionary       
    }


# -- set_content
#
# set the content branch of the page object for a specific content type and
# language. Meaningful content types are 'pagetext', 'header', 'title'

    ::itcl::body RWPage::set_content {language field value} {

        dict set content $language $field $value
        if {![dict exists $content $::rivetweb::default_lang $field]} {
            dict set content $::rivetweb::default_lang $field $value
        }
    }


# -- content
#
# crucial method printing to stdout the content for a specific language
# (when existing). This method prints output for the client, preprocessing
# postprocessing hooks (if applicable) must run beforehand

    
    ::itcl::body RWPage::content { pageobj language {fmt -reference}} {

    }


# -- languages
#
# returns a list of available languages for <pageobj>. The list is assumed
# to always have length > 0 as the default language has to be present
#

    proc languages { } {
        return $::rivetweb::default_lang
    }


# -- metadata
#
# when called with no argument 'metadata' returns the whole metadata section,
# when called with a 'key' argument the call returns the metadata value
# corresponding to the 'key'. If the 'key' metadata doesn't exist in the page
# object an empty string is returned.
# 

    ::itcl::body RWPage::metadata {{key ""}} {
        if {$key == "" } {
            return $metadata
        } else {

            if {[dict exists $metadata $key]} {
                return [dict get $metadata $key]
            } else {
                return ""
            }

        }
    }

# -- dispose
#
# releases objects which may hold data stored in the pool (e.g.
# tdom objects). Abstract method for this class

    proc dispose { } {

    }


    proc create {key {class static}} {

    }

    namespace export create
    namespace ensemble create
}
