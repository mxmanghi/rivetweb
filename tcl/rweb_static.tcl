#
# -- rweb_page.tcl
#
# base class for every page model providing for base
# methods and common interface to every other page model
#

package require Itcl
package require tdom
package require rwpage

namespace eval ::rwpage {

    ::itcl::class RWStatic {
        inherit RWPage

        private variable content

        constructor {pagekey} {RWPage::constructor $pagekey} {
            set content [dict create]
        }

        public method set_pagetext {language page_text {rootel "p"}} 
        public method set_content {field value} 
        public method postproc_hooks { hooks_d hooks_class {language ""}}
	public method print_content {language}
	public method languages { }
    }

# -- set_pagetext
#
#

    ::itcl::body RWStatic::set_pagetext {language page_text {rootel "p"}} {

        set page_dom  [dom createDocument pagetext]
        set page_o    [$page_dom documentElement]

        $page_o appendXML "<${rootel}>$page_text</${rootel}>"

        dict set content $language pagetext $page_dom
    }

# -- set_content
#
# set the content branch of the page object for a specific content type and
# language. Meaningful content types are 'pagetext', 'header', 'title'

    ::itcl::body RWStatic::set_content {language field value} {

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

    
    ::itcl::body RWStatic::content { pageobj language {fmt -reference}} {

    }

# -- content
#
# returns the content of <pageobj> for <language> and
# in one of four possible formats: 
#
#   1) '-xml': XML representation
#   2) '-text': Markup language is removed and text returned
#   3) '-html': HTML representation (thus not 'well formed')
#   4) '-reference': reference to internal object representation
#   

    proc content {language {fmt -reference}} {

        if {[dict exists $content $language]} {
            set page_content [dict get $content $language]
        } elseif {[dict exists $content $::rivetweb::default_lang]} {
            set page_content [dict get $content $::rivetweb::default_lang]
        } else {
            set errormsg "Inconsistent model: Missing data for default language"

            $::rivetweb::logger log emerg "inconsistent model: $this"
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


    ::itcl::body RWStatic::postproc_hooks { hooks_d hooks_class {language ""}} {

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

                set page_content [$this content $language -reference]
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

# -- print_content
# 
# 

    ::itcl::body RWPage::print_content {language} { } 

# -- languages
#
#
    ::itcl::body RWPage::languages { } {
	return [dict keys $content]
    }

}
package provide rwstatic 0.1
