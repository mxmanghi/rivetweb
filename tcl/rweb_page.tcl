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
        public method postproc_hooks { hooks_d hooks_class {language ""}}
        public method metadata_hooks { pageobj hooks_d } 
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

    ::itcl::body RWPage::dispose { } {

    }

# -- postproc_hooks
#
# general purpose method to call specific code for handling 
# elements of a page. It should be general enough to hide 
# the page internal implementation.
#
# When a transformation actually takes place a hook should return a dictionary 
# storing a new tag name (key: tagname), a list of transformed attributes 
# (key: attributes) and the new text within the element, if any (key: text).
# Otherwise the processor will return an empty string. 
#
#       <processor_name> { element_text attributes }
#

    ::itcl::body RWPage::postproc_hooks { hooks_d hooks_class {language ""}} {

        if {[dict exists $hooks_d $hooks_class]} {

            if {[string length $language] == 0} { 
                set language $::rivetweb::default_lang 
            }

# xmlpp is a subdictionary for hooks of 'hooks_class'
# the keys of the dictionary are the tag names to be manipulated

            set xmlpp [dict get $hooks_d $hooks_class]

            foreach hk [dict keys $xmlpp] {

                apache_log_error debug "processing hook: [dict get $xmlpp $hk descrip]"
                set processor [dict get $xmlpp $hk function]
                set text_mode "text"
                if {[dict exists $xmlpp $hk textmode]} {
                    set text_mode [dict get $xmlpp $hk textmode]
                }

# we must fetch the content for a specific language and get the 
# elements whose tag name is $hk. Tagname and attributes are then
# passed as arguments to the hook, which returns a new tag name
# and a new list of attributes which are to replace the element

                set page_content [[namespace current]::content $pageobj $language -reference]
                set page_xml [dict get $page_content pagetext]
                foreach el2xform [$page_xml getElementsByTagName $hk] {
                    
                    set attribute_list {}
                    foreach attr [$el2xform attributes] { 
                        lappend attribute_list $attr [$el2xform getAttribute $attr]
                    }
    
                    if {[string tolower $text_mode] == "xml"} {
                        set new_element_d [::rivetweb::$processor [$el2xform asXML -indent 2] $attribute_list]
                    } else {
                        set new_element_d [::rivetweb::$processor [$el2xform text] $attribute_list]
                    }
#                   apache_log_error debug $new_element_d
                    if {[string length $new_element_d]} {
                        set new_tag     [dict get $new_element_d tagname]
                        set attributes  [dict get $new_element_d attributes]

                        set new_element [$page_xml createElement $new_tag]

                        foreach {attrib attrib_value} $attributes {
                            $new_element setAttribute $attrib $attrib_value
                        }

                        [$el2xform parentNode] replaceChild $new_element $el2xform
                        if {[dict exists $new_element_d text]} {
                            set elem_text   [dict get $new_element_d text]
                            $page_xml createTextNode $elem_text new_element_text

                            $new_element appendChild $new_element_text
                        }
                        if {[dict exists $new_element_d expansion]} {
                            $new_element appendXML [dict get $new_element_d expansion]
                        }
                    }
                }
            }
        }

    }

# -- metadata_hooks
#
# metadata hooks are processed in a similar wayto xml postproc hooks, 
# but they apply in slightly different manner
#

    ::itcl::body RWPage::metadata_hooks { hooks_d } {

        if {[dict exists $hooks_d metadata]} {
            set ppp [dict get $hooks_d metadata]
            foreach hk [dict keys $ppp] {
                $::rivetweb::logger log info "processing hook: [dict get $ppp $hk descrip]"
                set processor [dict get $ppp $hk function]
                
                ::rivetweb::$processor $pageobj 

            }
        }
    }


    proc create {key {class static}} {

    }

    namespace export create
    namespace ensemble create
}
