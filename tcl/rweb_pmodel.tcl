# -- rweb_pmodel.tcl
#
# page model implementation. A page model handles 2 classes of data: 
#
#   1) the content of a page, a dictionary or other structured data 
# container capable of storing the content of a page in different 
# languages
#
#   2) The metadata of a page, an association between
# keywords and application defined data.
#
#

package require tdom
package require rwlogger
package require rwconf

namespace eval ::rwpmodel {

# -- create
#
# instantiation of a page model. In this implementation
# a page model is stored in a Tcl dictionary
#

    proc create {} {
        return [dict create]
    }

# -- add_metadata 
#
# method to store in a page instance the metadata associated
# with the keyword 'field' and whose value is 'value'
#
#

    proc add_metadata {pmodel field value} {
        upvar $pmodel page_object

        dict set page_object metadata $field $value
    }

# -- set_metadata
#
# the list 'mdlist' is treated as a even length set of keyword-value
# pairs. The keywords are assembled and become the new metadata of
# the instance 'pageobj' erasing metadata that could have been defined
# beforehand  

    proc set_metadata {pmodel mdlist} {
        upvar $pmodel page_model

        dict set page_model metadata [eval dict create $mdlist]
    }

# -- put_metadata 
# 
# like set_metadata with a dictionary as second argument instead of a 
# list
#

    proc put_metadata {pmodel dictionary} {
        upvar $pmodel page_model
 

        dict set page_model metadata $dictionary       
#       foreach k [dict keys $dictionary] {
#            dict set page_model metadata $k [dict get $dictionary $k]
#       }
    }

# -- set_content
#
# set the content branch of the page object for a specific content type and
# language. Meaningful content types are 'pagetext', 'header', 'title'
#

    proc set_content {pmodel language field value} {
        upvar $pmodel page_model

        dict set page_model content $language $field $value
        if {![dict exists $page_model content $::rivetweb::default_lang $field]} {
            dict set page_model content $::rivetweb::default_lang $field $value
        }
    }

# -- set_pagetext
#
#
#

    proc set_pagetext {page language page_text {rootel "p"}} {
        upvar $page pageobj

        set page_dom  [dom createDocument pagetext]
        set root_node [$page_dom createElement $rootel]        
        set page_o    [$page_dom documentElement]
        $page_o appendChild $root_node

        set message_o [$page_dom createTextNode $page_text]
        
        $root_node appendChild $message_o
        dict set pageobj content $language pagetext $page_dom

        return $pageobj
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
