# -- rivetweb
#
# The core functions of Rivetweb
#
#

package require rwconf
package require rwebdb
package require rwlogger

package require rwlink
package require rwmenu
package require rwsitemap
package require htmlizer

namespace eval ::rivetweb {

# -- field
#
# field is a convenience proc that checks for the existence
# of a variable in an array. The function generates an error
# if the variable doesn't exist that can be caught for handling
#  
# Input: a       - array name
#        field   - name of the variable in the array
#
#

    proc field {a field} {
        upvar $a a
        
        if {[info exists a($field)]} { 
            return -code ok $a($field) 
        } else {
            return -code error
        }
    }

# -- makeUrl
#
# Central method for generating hypetext links pointing to other pages of the 
# site.
#
# References are built accordingly with the mode we are generating a page
# (either static or dynamic). In case the 'lang' or 'reset' parameters are 
# passed in their values are appended to the local path
#
#
# Arguments:
#
#   reference:  a string that works as a key to the page to be generated. 
#  		A value
#               'key' maps to 'index.rvt?show=<key>....' in dynamic mode or
#               to '/static/<key>.html' in static mode. 
#
# Returned value:
#
#   the URL to the page in relative form.
#

    proc makeUrl {reference} {
#       puts "generate reference for '$reference' (static = $::rivetweb::static_links)"

        if {$::rivetweb::static_links} {
#           apache_log_error err "static_links flag $::rivetweb::static_links"
            if {([string length $reference] == 0) || \
                 [string equal $reference index]}  {
                if {$::rivetweb::is_homepage} {
                    return index.html
                } else {
                    return [file join .. index.html]
                }
            } else {
                if {$::rivetweb::is_homepage} {
                    return [file join $::rivetweb::static_path ${reference}.html]
                } else {
                    return ${reference}.html
                }
            }
        } else {

            if {[string length $reference] == 0} {
                set reference $::rivetweb::index
            }

# we use therefore ::request::env(DOCUMENT_NAME) to infer the template name

            if {[info exists ::rivetweb::env(DOCUMENT_NAME)]} {
                set local_ref "$::rivetweb::env(DOCUMENT_NAME)?show=${reference}"
            } else {
                set local_ref "index.rvt?show=${reference}"
            }

# structural variables passover

            if {[var exists lang]} { 
                set local_ref "${local_ref}&lang=[var get lang]" 
            }
            if {[var exists reset]} { 
                set local_ref "${local_ref}&reset=[var get reset]" 
            }
            if {[var exists template]} { 
                set local_ref "${local_ref}&template=[var get template]" 
            }
            return $local_ref
        }
    }

    namespace export makeUrl


# -- buildSimplePage 
#
# Utility function that builds a simple page out of a message 
# 
# Arguments: 
#
#    - mag	    Message text
#    - cssclass     css class the element enclosing the text must have
#    - pagina_id    identification of the page for subsequent retrieving 
#                   from the cache
#
#  Returned value:
#
#   - reference to the tdom object representing the page
#

    proc buildSimplePage {msg cssclass pagina_id} {

        if {![info exists ::rivetweb::pagine($pagina_id)]} {
            set msgdom  [dom createDocument page]
            set xml_o   [$msgdom documentElement]

# Let's add the menus to the dom

            set menu_o  [$msgdom createElement menu]
            $xml_o appendChild $menu_o
            set t   [$msgdom createTextNode "index"]
            $menu_o appendChild $t

# ...and then the page main content

            set content_o [$msgdom createElement content]
            $xml_o appendChild $content_o

            set headline_o [$msgdom createElement headline]
            set hdline_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $headline_o appendChild $hdline_to
            set title_o   [$msgdom createElement title]
            set title_to  [$msgdom createTextNode "Rivetweb anomaly"]
            $title_o    appendChild $title_to
            $headline_o appendChild $hdline_to
            $content_o  appendChild $headline_o
            $content_o  appendChild $title_o

            set htmldiv_o [$msgdom createElement pagetext]
            $content_o appendChild $htmldiv_o
            eval $htmldiv_o setAttribute class $cssclass 

            set t [$msgdom createTextNode $msg]
            $htmldiv_o appendChild $t

        } else {
            set msgdom $::rivetweb::pagine($pagina_id)
        }

        return $msgdom
    }
    namespace export buildSimplePage

# -- makeCssPath 
#
#   creates rivetweb path to a CSS file
#
# Arguments:
#
#	css_file:   CSS file name
#	style_dir:  template/CSS key
#
# style_dir is supposed to be a 'key' in a database of templates, it
# represents the directory name where the CSS is located within the 
# ::rivetweb::running_css_path directory containing the css files for 
# the supported templates.
#

    proc makeCssPath {css_file {style_dir ""}} {
        return [file join $::rivetweb::running_css_path $style_dir $css_file] 
    }
    namespace export makeCssPath

# -- makePictsPath
#
# 

    proc makePictsPath {picts_file {style_dir ""}} {

        apache_log_error debug "style $style_dir $::rivetweb::running_picts_path [pwd]"

# search list for a picts file. 
#    - We first try in the template's specific dir
#    - then we try the picts root directory 
#    - then we try in the website root 'picts' directory
#    - last we attempt in the rwbase dir


# we have to fake static links (relative to the ::rivetweb::static_path variable)
# but still be aware we are running from /index.rvt

        set fn [file join   $::rivetweb::site_base      \
                            $::rivetweb::base_templates \
                            $style_dir                  \
                            picts $picts_file]

        apache_log_error debug "0 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::base_templates $style_dir picts $picts_file]
        }

        set fn [file join   $::rivetweb::site_base  \
                            $::rivetweb::picts_path \
                            $style_dir              \
                            $picts_file]

        apache_log_error debug "1 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $style_dir $picts_file]
        } 

        set fn [file join   $::rivetweb::site_base    \
                            $::rivetweb::picts_path   \
                            $picts_file]

        apache_log_error debug "2 pict file: >$fn<"
        if {[file exists $fn]} {
            return [file join $::rivetweb::running_picts_path $picts_file]
        } 

        set fn [file join   $::rivetweb::site_base          \
                            $::rivetweb::picts_path         \
                            $::rivetweb::default_template   \
                            $picts_file]

        apache_log_error debug "3 pict file: >$fn<"
        return [file join   $::rivetweb::running_picts_path   \
                            $::rivetweb::default_template     \
                            $picts_file]
    }
    namespace export makePictsPath


# -- template_path
#
# 

    proc template_path {template_name {template_dir ""}} {
        return [file join $::rivetweb::base_templates $template_dir $template_name]
    }
    namespace export template_path

# -- thisClass 
#
# returns a class="classname" attribute when we are generating
# a certain page. Useful in selectors both in forms or templates to highlight
# an element.

    proc thisClass {this_page page_reference class_selected {class_unselected ""}} {
        if {[string match $this_page $page_reference]} { 
            return " class=\"$class_selected\""
        } else {
            return ""
        }
    }
    namespace export thisClass

# -- itemSerialize 
#
# takes a tdom element object and makes a list of the child 
# elements and their text nodes.
# Useful when a tdom element's children are leaves of the tree
#

    proc itemSerialize {itemObj} {
        set lista {}
        foreach c [$itemObj child all] {
            lappend lista [$c tagName] [$c text]
        }
        return $lista
    }

# -- selectContent
#
# Another Rivetweb's key feature is the ability to produce output
# in different languages, provided text for links and content is
# available for a language different from the default language.
#
# This procedure seeks for the right content in a xml_page
# depending on the language 
#
# Arguments:
#
#   - xml_page: tdom object reference representing the page
#   - lang: language to be sought
#   - content_selected: name of a variable in the caller scope
#     where the content will be stored
#
# Returned value:
#
#   - either true or false depeding on the search operation 
#     success
#

    proc selectContent {xml_page lang content_selected} {
        upvar $content_selected content

# peeking the root of the page
        set xmlroot [$xml_page documentElement root]

# we set an empty default_content to test if the page was consistent.
 
        set default_content ""
        set retv true
        foreach content [$xmlroot getElementsByTagName content] {
            if {[$content hasAttribute language]} {
                set clang [$content getAttribute language]
                apache_log_error debug "$content: ($clang)"         
                if {[string equal $clang $lang]} {
                    return true
                } elseif {[string match $clang $::rivetweb::default_lang]} {
                    set default_content $content
                }
            } else {
                set default_content $content
#               puts stderr "$content: ($::rivetweb::default_lang) [$content text]"
            }
        }
        
        if {[string match $default_content ""]} {
            set retv false
        } else {
            set content $default_content
        }
        return $retv
    }

    namespace export selectContent


    proc getElementValue {xml tag} {
        set xmlroot [$xml documentElement root]
        set testo    ""
        set elementi [$xmlroot getElementsByTagName $tag]
        foreach elemento $elementi {
            append testo [$elemento text]
        }
        return $testo
    }

# -- makePageHTML 
#
#

    proc makePageHTML {xmldoc content_a} {
        upvar $content_a content_html 

        set content_html ""
        set xmlnode_pt [$xmldoc documentElement]

        if {[string match [$xmlnode_pt nodeName] pagetext]} {

            foreach el [$xmlnode_pt childNodes] {
                append content_html "[$el asXML -indent 1]\n"
            }

            return true
        } else {
            return false
        }
    }

# -- isDebugging 
#
#

    proc isDebugging { } {
        return [expr $::rivetweb::debug && [var exists debug]]
    }

 
# -- contentType
#
# Returns a 'meta' XHTML tag element specifying the content type
# and charset as stored in 

    proc contentType {} {
        return "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=$::rivetweb::http_encoding\" />"
    }

# -- searchPath 
# 
# looks for <filename> in a sequence of paths given in <pathList>
# and returns the actual path (absolute path) if found, otherwise
# returns an empty string
#

    proc searchPath {fileName pathList} {

        foreach pth $pathList {

            set fn [file join $pth $fileName]

            if {[file exists $fn]} {
                return [file normalize $fn]
            }
        }
        return ""
    }
    namespace export searchPath

}

package provide rivetweb 2.0

