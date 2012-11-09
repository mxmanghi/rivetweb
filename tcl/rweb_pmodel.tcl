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
# the list 'mdlist' is treated as a even length list to be interpreted
# as a sequence of keyword-value pairs. 
# The keywords are assembled and become the new metadata of
# the instance 'pageobj' erasing metadata that could have been defined
# beforehand  

    proc set_metadata {pmodel mdlist} {
        upvar $pmodel page_model

        dict set page_model metadata [eval dict create $mdlist]
    }

# -- put_metadata 
# 
# like set_metadata with a dictionary as second argument instead of a list
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

    proc set_pagetext {page language page_text {rootel "p"}} {
        upvar $page pageobj

        set page_dom  [dom createDocument pagetext]
        set page_o    [$page_dom documentElement]

        $page_o appendXML "<${rootel}>$page_text</${rootel}>"

        dict set pageobj content $language pagetext $page_dom
        return $pageobj
    }

# -- content
#
# returns the content of <pageobj> for <language> and
# in one of four possible formats: 
#
#   1) '-xml': XML representation
#   2) '-text': Markup language is removed and text in it returned
#   3) '-html': HTML representation (thus not 'well formed')
#   4) '-reference': reference to internal object representation
#   

    proc content { pageobj language {fmt -reference}} {

        if {[dict exists $pageobj content $language]} {
            set page_content [dict get $pageobj content $language]
        } elseif {[dict exists $pageobj content $::rivetweb::default_lang]} {
            set page_content [dict get $pageobj content $::rivetweb::default_lang]
        } else {
            set errormsg "Inconsistent model: Missing data for default language"

            $::rivetweb::logger log emerg "inconsistent model: $pageobj"
            return -code error  -errorcode missing_default_content  \
                                -errorinfo $errormsg $errormsg
        }

        switch -nocase -- $fmt {
            -xml {
                set method asXML
            }
            -text {
                set method asText
            }
            -html {
                set method asHTML
            }
            default {
                set method ""
            }
        }

# we prepare the data for display in another dictionary
# title and headline are choosen from more to less specific, with
# headline falling back to title if not resolvable

        set page_data [dict create]

        foreach {key field} $page_content {

            switch $key {

                title - 
                headline {
                    dict set page_data $key $field
                }

                pagetext {
                    if {[string length $method] == 0} {
                        dict set page_data $key $field
                    } else {

                        set output_buffer ""
                        set xmlnode_pt [$field documentElement]
                        if {[string match [$xmlnode_pt nodeName] pagetext]} {

                            foreach el [$xmlnode_pt childNodes] {
                                append output_buffer "[$el $method]\n"
                            }

                            dict set page_data pagetext $output_buffer
                        } else {
                            set errormsg "Inconsistent model: Missing 'pagetext' tag for language $language"

                            $::rivetweb::logger log emerg "inconsistent model: $pageobj"
                            return -code error  -errorcode missing_default_content  \
                                                -errorinfo $errormsg $errormsg
                        }
                    }
                }
            }
        }


        if {![dict exists $page_data headline]} {
            if {[dict exists $pageobj metadata headline]} {
                dict set page_data headline [dict get $pageobj metadata headline]
            } elseif {[dict exists $page_data title]} {
                dict set page_data headline [dict get $page_data title]
            } elseif {[dict exists $pageobj metadata title]} {
                dict set page_data headline [dict get $pageobj metadata title]
            }
        } 

        if {![dict exists $page_data title]} {
            if {[dict exists $pageobj metadata title]} {
                dict set page_data title [dict get $pageobj metadata title]
            } else {
                dict set page_data title ""
            }
        }

        return $page_data
    }


# -- languages
#
# returns a list of available languages for <pageobj>. The list is assumed
# to always have length > 0 as the default language has to be present
#

    proc languages { pageobj } {
        return [dict keys [eval dict create [dict get $pageobj content]]]
    }


# -- metadata
#
# when called with one argument 'metadata' returns the whole metadata section,
# when called with a second 'key' argument the call returns the metadata value
# corresponding to the 'key'. If the 'key' metadata doesn't exist in the page
# object an emty string is returned.
# 

    proc metadata { pageobj {key ""} } {

        if {$key == "" } {

            return [dict get $pageobj metadata]

        } else {

            if {[dict exists $pageobj metadata $key]} {
                return [dict get $pageobj metadata $key]
            } else {
                return ""
            }
        }
    }

# -- mdmodel (deprecated)
#
# to be moved into 'legacy'
#
    proc mdmodel { pmodel field } {
        if {[dict exists $pmodel metadata $field]} {
            return [dict get $pmodel metadata $field]
        } else {
#           puts "$pmodel: $field"
            return ""
        }
    }

# -- dispose
#
# deletes the storage <pageobj> internal data, making possible to 
# dispose of the <pageobj> itself
# 

    proc dispose { pageobj } {
            
        foreach {language v} [dict get $pageobj content] {
            set pagedom [dict get $pageobj content $language pagetext]
            $pagedom delete
        }

    }

# -- metadata_hooks
#
# metadata hooks are processed in a similar wayto xml postproc hooks, 
# but they apply in slightly different manner
#

    proc metadata_hooks { pageobj hooks_d } {

        if {[dict exists $hooks_d metadata]} {
            set ppp [dict get $::rivetweb::hooks metadata]
            foreach hk [dict keys $ppp] {
                $::rivetweb::logger log info "processing hook: [dict get $ppp $hk descrip]"
                set processor [dict get $ppp $hk function]
                
                ::rivetweb::$processor $pageobj 

            }
        }
    }

# -- postproc_hooks
#
# general purpose method to call specific code for handling 
# elements of a page. It should be general enough to hide 
# the page internal implementation.
#
# When a transformation actually tooks place a hook should return a dictionary 
# storing a new tag name (key: tagname), a list of transformed attributes 
# (key: attributes) and the new text within the element, if any (key: text).
# Otherwise the processor will return an empty string. 
#
#       <processor_name> { element_text attributes }
#

    proc postproc_hooks { pageobj hooks_d hooks_class {language ""}} {

        if {[dict exists $hooks_d $hooks_class]} {

            if {[string length $language] == 0} { 
                set language $::rivetweb::default_lang 
            }

# xmlpp is a subdictionary for hooks of 'hooks_class'
# the keys of the dictionary are the tag names to be manipulated

            set xmlpp [dict get $::rivetweb::hooks $hooks_class]

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


    namespace export *
    namespace ensemble create
}

package provide rwpmodel 0.1
