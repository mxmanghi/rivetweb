#
# -- rweb_static.tcl
#
# Class for static pages whose content is represented 
# as a tdom object instance
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

    # we store an initial text object. The content variable 
    # cannot fail to return a pagetext value

            set page_dom  [dom createDocument pagetext]
            set page_o    [$page_dom documentElement]
            $page_o appendXML "<div>undefined</div>"
            dict set content $::rivetweb::default_lang pagetext $page_o
        }

        public method destroy {}
        public method set_pagetext {language page_text {rootel "p"}} 
        public method set_content {language field value} 
        public method postproc_hooks {ds hooks_d hooks_class {language ""}}
        public method print_content {language}
        public method languages {}
        public method content {language {fmt -reference}}
        public method to_string {}
        public method title {language}
        public method headline {language}
        public method content_field {language field {default_val ""}}
    }


    ::itcl::body RWStatic::destroy { } {
        foreach l [dict keys $content] {
            set pagedom [dict get $content $l pagetext]
            $pagedom delete
        }
        
        RWPage::destroy
    }

# -- set_pagetext
#
#
    ::itcl::body RWStatic::set_pagetext {language page_text {rootel "p"}} {

        set page_dom  [dom createDocument pagetext]
        set page_o    [$page_dom documentElement]

        $page_o appendXML "<${rootel}>$page_text</${rootel}>"

        if {![catch {set pageref [$this content $language]} e]} {
            $pageref delete
        }

        $this set_content $language pagetext $page_dom

    }

# -- set_content
#
# set the content branch of the page object for a specific content type and
# language. Meaningful content types are 'pagetext', 'header', 'title'
#
    ::itcl::body RWStatic::set_content {language field value} {

        dict set content $language $field $value
        if {![dict exists $content $::rivetweb::default_lang $field]} {
            dict set content $::rivetweb::default_lang $field $value
        }

    }

# -- content
#
# crucial method returning the content for a specific language
# (when existing). Depending on the value of argument fmt
# 'content' returns the output as
#
#    -xml   well formed XML page
#    -text  pure text stripped of the markup
#    -html  HTML code as output of asHTML of tdom
#    -reference (default) tdom object reference
#
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

        if {[dict exists $content $language pagetext]} {
            set pagedom [dict get $content $language pagetext]
        } elseif {[dict exists $content $::rivetweb::default_lang pagetext]} {
            set pagedom [dict get $content $::rivetweb::default_lang pagetext]
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
		        return $pagedom
            }
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

    ::itcl::body RWStatic::postproc_hooks { datasource hooks_d hooks_class {language ""}} {

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

                set page_xml [$this content $language -reference]
                #set page_xml [dict get $page_content pagetext]
                foreach el2xform [$page_xml getElementsByTagName $hk] {
                    
                    set attribute_list {}
                    foreach attr [$el2xform attributes] { 
                        ::lappend attribute_list $attr [$el2xform getAttribute $attr]
                    }

                    if {[string tolower $text_mode] == "xml"} {
                        set new_element_d [::rivetweb::$processor $datasource $hk \
                                          [$el2xform asXML -indent 2] $attribute_list]
                    } else {
                        set new_element_d [::rivetweb::$processor $datasource $hk \
                                          [$el2xform text] $attribute_list]
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

    ::itcl::body RWStatic::print_content {language} {
        puts -nonewline [$this content $language -xml]
    } 

# -- languages
#
#
    ::itcl::body RWStatic::languages { } {
	return [dict keys $content]
    }

# -- to_string 
#
#

    ::itcl::body RWStatic::to_string {} { 
        return [dict merge [chain] $content]
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

# -- content_field
#
#

    ::itcl::body RWStatic::content_field {language field {default_val ""}} {
        if {[dict exists $content $language $field]} {
            return [dict get $content $language $field]
        } else {
            return $default_val
        }
    }
}

package provide rwstatic 0.1
