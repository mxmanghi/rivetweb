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
        public method set_content {language field value} 
        public method postproc_hooks { hooks_d hooks_class {language ""}}
#       public method print_content {language}
        public method languages {}
        public method content {language {fmt -reference}}
        public method to_string {}
        public method title {language}
        public method headline {language}
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

    
    ::itcl::body RWStatic::content { language {fmt -reference}} {

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
                return [dict get $content $language]
            }
        }

        if {[dict exists $content $language pagetext]} {
            set pagedom [dict get $content $language pagetext]
        } elseif {[dict exists $content $::rivetweb::default_lang pagetext]} {
            set pagedom [dict get $content $default_lang pagetext]
        }

        if {[info exists pagedom]} {
            set xmlnode_pt [$pagedom documentElement]

            if {[string match [$xmlnode_pt nodeName] pagetext]} {

                foreach el [$xmlnode_pt childNodes] {
                    append output_buffer "[$el $method]\n"
                }

            } else {
                set errormsg "Inconsistent model: Missing 'pagetext' tag for language $language"

                $::rivetweb::logger log emerg "inconsistent model: $pageobj"
                return -code error  -errorcode missing_default_content  \
                                    -errorinfo $errormsg $errormsg
            }
        } else {
            set output_buffer "No Data"
        }
        return $output_buffer
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

## -- print_content
## 
## 
#
#   ::itcl::body RWStatic::print_content {language} { } 

# -- languages
#
#
    ::itcl::body RWStatic::languages { } {
	    return [dict keys $content]
    }

# -- to_string 
#

    ::itcl::body RWStatic::to_string {} { 
        set buffer [chain]

        append buffer $content
        return $buffer
    }

# -- title
#
# concrete implementation that fetches the page title
# from the 'content' of a static page
#

    ::itcl::body RWStatic::title {language} {
        if {[dict exists $content $language title]} {
            return [dict get $content $language title]
        } else {
            return [$this metadata title]
        }
    }

# -- headline
#
#

    ::itcl::body RWStatic::headline {language} {
        if {[dict exists $content $language headline]} {
            return [dict get $content $language headline]
        } else {
            return [$this title $language]
        }
    }
}
package provide rwstatic 0.1
