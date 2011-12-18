# 
# $Id: makepagehtml.tcl 2094 2011-12-14 16:25:05Z massimo.manghi $
#
#+
# rivetweb procedure for handling the DOM of a page and generating
# XHTML output. These procedure are defined within the ::rivetweb 
# namespace
#-
#
# Changelog:
#
# 11 Nov 2011:  This file is sourced by rivet_page.tcl within
#               the ::rivetweb namespace
#


# -- xmlPostProcessing
# 
# This procedure implements a key feature of Rivetweb, since
# it catches every element in a page and special elements
# are elaborated and rewritten in the DOM.
# 
# The whole process is largely and awfully suboptimal though
# and it should be matter of reckoning and careful pondering
# for a deep rewriting
# 
#  Arguments: 
#    - xmlDoc: tdom object representing the page
#
#  Returned value:
#    - the tdom object reelaborated.
#

proc xmlPostProcessing {xmlDoc} {


    foreach child [$xmlDoc getElementsByTagName externref] {
        if {[$child hasAttribute href]} {
            set anchor_text [$child asText]

            $xmlDoc createTextNode $anchor_text new_anchor_txt
            set newAnchorElement [$xmlDoc createElement a]
            foreach refattr [$child attributes] {
                set attvalue [$child getAttribute $refattr]
                $newAnchorElement setAttribute $refattr $attvalue
            }
            $newAnchorElement setAttribute target _blank 

            $newAnchorElement appendChild $new_anchor_txt
            [$child parentNode] replaceChild $newAnchorElement $child
            $child delete     
        }
    }


    foreach child [$xmlDoc getElementsByTagName localref] {
        if {[$child hasAttribute href]} {
            set page_ref    [$child getAttribute href]
            set anchor_text [$child asText]

            $xmlDoc createTextNode $anchor_text new_anchor_txt
            set newAnchorElement [$xmlDoc createElement a]

            $newAnchorElement setAttribute href $page_ref
            $newAnchorElement appendChild $new_anchor_txt
            [$child parentNode] replaceChild $newAnchorElement $child
            $child delete
        }
    }
    return $xmlDoc
}
namespace export xmlPostProcessing


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
#


proc selectContent {xml_page lang content_selected} {
    upvar $content_selected content

#   puts stderr "seeking content for language $lang"

    set xmlroot [$xml_page documentElement root]
    set default_content ""
    set retv true
    foreach content [$xmlroot getElementsByTagName content] {
        if {[$content hasAttribute language]} {
            set clang [$content getAttribute language]
#           puts stderr "$content: ($clang) [$content asXML]"
            if {[string equal $clang $lang]} {
#               puts stderr "content found ($clang)"
                return true
            } elseif {[string match $clang $::rivetweb::default_lang]} {
                set default_content $content
            }
        } else {
            set default_content $content
#           puts stderr "$content: ($::rivetweb::default_lang) [$content text]"
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

# proc makePageHTML {xmldoc xmlnode_content title_v headline_v pagetext_v} 
proc makePageHTML {xmldoc xmlnode_content content_a} {
    upvar $content_a content  

    if {[string match [$xmlnode_content nodeName] content]} {
        foreach el [$xmlnode_content childNodes] {
#           puts "<pre>processing element [$el nodeName]</pre>"
            switch [$el nodeName] {
                title {
                    set content(title) [$el text]
                }
                headline {
#                   puts [escape_sgml_chars [$el asText]]
                    set content(headline) [$el asXML]
                }
                pagetext {
                    set content(pagetext) ""
                    foreach txtElement [$el childNodes] {
                        append content(pagetext) "[$txtElement asXML -indent 1]\n"
                    }
#                   puts stderr $pagetext
                }
            }
        }

        if {![info exists content(headline)] && [info exists content(title)]} {
            set content(headline) $content(title)
        } elseif {![info exists content(title)] && [info exists content(headline)]} {
            set content(title)  $content(headline)
        }

        return true
    } else {
        return false
    }
}

# vi:shiftwidth=4:softtabstop=4:
