# -- legacy.tcl
#
#
#

namespace eval ::rivetweb {

# -- menuTitle
#
# menuTitle accepts a rivetweb xml object as argument. The procedure
# returns the contents of title element. 
#

    proc menuTitle {menuObj {language en}} {
        set title_candidate ""
        set title_objs  [$menuObj getElementsByTagName title]
        foreach tobj $title_objs {
            if {[$tobj hasAttribute language]} {
                set obj_l [$tobj getAttribute language]
                if {[string match $language $obj_l]} { return [$tobj text] }
            } else {
                set title_candidate [$tobj text]
            }
        }
        return $title_candidate
    }

# -- menuItems
#
# tdom objects representing the menu items are extracted and returned
# in a list
#

    proc menuItems {menuObj} {
        set items {}
        foreach c [$menuObj childNodes] {
            if {[string match [$c nodeType] ELEMENT_NODE] && \
                [string match [$c nodeName] link]} {
                lappend items $c
            }
        }
        return $items
    }



# -- htmlMenu 
#
# takes a tdom object command from the menu dom and generates the html
# code for the menu. This procedure uses tdom calls in order to obtain an xhtml
# page fragment.
#
# This is the general dom pseudo-structure of the menu 
#
# - <$menu_tag class="$menu_class" id="$menu_id">
#       <$title_tag class="$title_class"> $titolo_txt </$title_tag>
#         <div class="itemcontainer">
#             <span class="navitem"><a href="<hypetext-link-1>" class="$item_class" title="<info-1>"> 
#                link 1 </span>
#             <span class="navitem"><a href="<hypetext-link-2>" class="$item_class" title="<info-2>">
#                link 2 </span>
#       ....
#         </div>
#       </div>
#   </$menu_tag>
#
#
#   Arguments: 
#
# - menuObj: tdom object representing the menu to be printed
#     - lang: language code
# - menu_html: 2 element list.
#
#	  * Element 0: html element tag that will encompass the whole menu 
#                  (default: div)
#	  * Element 1: css class for the element (default: staticmenu)
#
# - title_html: 2 element list
#		* Element 0: html element tag enclosing the menu title (def: div)
#		* Element 1: css class for the element (default: menuheader)
#
# - it_cont_html: 2 element list
#		* Element 0: html element tag enclosing the menu items (def: div)
#		* Element 1: css class for the element (default: itemcontainer)
# - item_html: 2 element list
#		* Element 0: html element delimiting an item (def: span)
#		* Element 1: css class for the element (default: navitem)
#
#   Returned value:
#
#	menu in XHTML 
#           
#proc htmlMenu {  menuObj {lang ""}                      \
#                {menu_html {div staticmenu}}            \
#                {title_html {div menuheader}}           \
#                {it_cont_html {div itemcontainer}}      \
#                {item_html {span menuitem}}             \
#                {link_class navitem} } 

    proc htmlMenu { menuObj lang menustruct } {

# let's remap menustruct into local variables

        foreach {v lv} $menustruct { set $v $lv }

# we extract tag and class names from the variable lists passed in
# by 'menustruct'

        set menu_class      [lindex $menu_html 1]
        set menu_tag        [lindex $menu_html 0]
        set title_class     [lindex $title_html 1]
        set title_tag       [lindex $title_html 0]
        set it_cont_tag     [lindex $it_cont_html 0]
        set it_cont_class   [lindex $it_cont_html 1]
        set item_tag        [lindex $item_html 0]
        set item_class      [lindex $item_html 1]

        if {([$menuObj tagName] eq "menu") && [$menuObj hasAttribute id]} { 
            if {$lang == ""} { set lang $::rivetweb::language }

            set menuid [$menuObj getAttribute id]
            set menuattributes  ""
            if {[$menuObj hasAttribute attr]} {
                set menuattributes  [split [$menuObj getAttribute attr] ","]
            } 
            set menudom [dom createDocument $menu_tag]
            set htmlmenu_o  [$menudom documentElement]
            eval $htmlmenu_o setAttribute id $menuid
            if {[string length $menu_class]} { 
            	eval $htmlmenu_o setAttribute class $menu_class 
            }

            if {[lsearch $menuattributes "notitle"] < 0} {
                set titolo_txt  [menuTitle $menuObj $lang]
                if {[string length $titolo_txt]} {
                    set  titolo_o [$menudom createElement $title_tag]
                    $titolo_o setAttribute class $title_class
                    $htmlmenu_o appendChild $titolo_o

                    set t [$menudom createTextNode $titolo_txt]
                    $titolo_o appendChild $t
                }
            }

            set item_container_o [$menudom createElement $it_cont_tag]
            $item_container_o setAttribute class $it_cont_class
            $htmlmenu_o appendChild $item_container_o

            foreach item_o [menuItems $menuObj] {
                array unset item_text
                array unset item_a

#               puts "<pre>[escape_sgml_chars [$item_o asXML]]</pre>"
                foreach c [$item_o child all] {
                    set tag_name [$c tagName]
                    switch $tag_name {
                        text {
                            if {[$c hasAttribute language]} {
                                set item_language [$c getAttribute language]
#                               if {[string match [$c getAttribute language] \
#						    $::rivetweb::language]} { \
#                                   set item_text($item_language) [$c text]
#                               }
                                set item_text($item_language) [$c text]
                            } else {
                                set item_text($::rivetweb::default_lang) \
                                				[$c text]
                            }
                        }
                        default {
                            set item_a($tag_name) [$c text]
                        }
                    }
                }

                if {![info exists item_text($::rivetweb::default_lang)]} {
                    set item_text($::rivetweb::default_lang) [$c text]
                }

                if {$::rivetweb::language == ""} {
                    set item_a(text)    $item_text($::rivetweb::default_lang)
                } elseif {[info exists item_text($lang)]} {
                    set item_a(text)    $item_text($::rivetweb::language)
                } else {
                    set item_a(text)    $item_text($::rivetweb::default_lang)
                }

#               array set item_a [itemSerialize $item_o]
            
                set item_range_o [$menudom createElement $item_tag]
                $item_range_o setAttribute class $link_class
                $item_container_o appendChild $item_range_o

                set link_o [$menudom createElement a]
                $item_range_o appendChild $link_o

                if {[info exists item_a(type)]} {
                    if {[info exists item_a(text)]} {
                        set t [$menudom createTextNode $item_a(text)]
                        $link_o appendChild $t
                    }
                    if {[info exists item_a(info)]} {
                        $link_o setAttribute title $item_a(info)
                    }
                    if {[info exists item_a(target)]} {
                        $link_o setAttribute target $item_a(target)
                    }

#                   puts "<div>type $item_a(type)</div>"
                    switch $item_a(type) {
                        internal {
                            if {[info exists item_a(reference)]} {
                                $link_o setAttribute href \
                                		[makeUrl $item_a(reference)]
                            }
                            $link_o setAttribute class $item_class
                        }
                        external {
                            if {[info exists item_a(url)]} {
                                $link_o setAttribute href "$item_a(url)"
                            }
                        }
                        local {
                            if {[info exists item_a(reference)]} {
                                $link_o setAttribute href "$item_a(reference)"
                            }
                        }
                    }
                }
            }
            set htmlMenu [$menudom asXML]
            $menudom delete
            return $htmlMenu
        } else {
            return ""
        }
    }

    namespace export menuHtml

# -- buildPageDOM 
#
# does the actual work of building a dom tree of objects from 
# the page xml description 
# 
# Arguments:
#   
#   -xmldata:   xml text from which we are building a tdom 
#               document reference
#   -pageid:    name of a caller's variable that will contain the
#               real pageid. Site pages have an id attribute that
#               identifies them. This variable will contain this
#               attribute's value.
#
# Returned value:
#   
#   - page dom reference
#

    proc buildPageDOM {xmldata pageid} {
        upvar $pageid page_id

        set pagedom [dom parse $xmldata]
        set domroot [$pagedom documentElement root]
        if {[$domroot hasAttribute id]} {
            set page_id [$domroot getAttribute id]
        }

        return $pagedom
    }

# -- buildPage 
#
# gets a keyword to the page that has to be generated. 
# The content of the page will read from the file <keyword>.xml
# 
# arguments: 
#
#   - page_keyword:     keyword to the page to be generated
#   - paginaid:         actual xml id of the loaded page in case some
#                       redirection mechanism gets triggered within 
#                       buildPage (not yet implemented)
#

    proc buildPage {page_keyword {paginaid paginaid} {language ""}} {
        upvar $paginaid page_id
        
        if {$language == ""} { set language $::rivetweb::default_lang }

        set xmlfile [file join $::rivetweb::static_pages ${page_keyword}.xml]
        apache_log_error debug "->opening $xmlfile" 
        if {[file exists $xmlfile]} {
            if {[catch {
                set xmlfp    [open $xmlfile r]
                set xmldata  [read $xmlfp]
                set xmldata  [regsub -all {<\?} $xmldata {\&lt;?}]
                set xmldata  [regsub -all {\?>} $xmldata {?\&gt;}]
#               puts stderr $xmldata
                close $xmlfp
            } fileioerr]} {
                set page_id errore_interno
                set notfound_msg "It was impossible to open the requested page ($fileioerr)"
                apache_log_error err "[pid] $notfound_msg"
                return [::rivetweb::buildSimplePage $notfound_msg message internal_error]
            } else {
                set pagedom [buildPageDOM $xmldata page_id]
#               if {[isDebugging]} { puts stderr "---> [$pagedom asXML]" }
                return $pagedom
            }
        } else {
            apache_log_error err "$xmlfile not found"
            set page_id not_existing
            set notexists_msg "The requested page does not exist"
            return [::rivetweb::buildSimplePage $notexists_msg message $page_id]
        }
    }
    namespace export buildPage

# -- walkTree
#
# walks the menu tree and builds a new tree where only 'node' menu
# are present starting from a leaf group of menus upwards to the root
#
# Arguments: 
#
#   radice: dom element root of the tree
#   node: 
#

    proc walkTree { radice node {eltype "node"} {menu_list {}} } {
     
        set menublock [$radice selectNodes {//sitemenus[@id=$node]}]
        if {$menublock == ""} { return $menu_list }
        if {[$menublock hasAttribute parent]} {

            set parent_block [$menublock getAttribute parent]

        } elseif {[$menublock hasAttribute id]} {

            if {[$menublock getAttribute id] == "root"} { set parent_block "" }

        } else {

            return  -code	    error                \
                    -errorcode  inconsistent_tree    \
                    -errorinfo  "Struttura menu inconsistente (manca 'radice')" $menu_list
        }

        set ml { }
        foreach cn [$menublock childNodes] {
            if {[$cn nodeName] == "menu"} {
                if {[$cn hasAttribute type]} {
                    set tipo [$cn getAttribute type]
                } else {
                    set tipo leaf
                }

                if {($tipo == "node") || ($eltype == $tipo)} {
                    lappend ml $cn
                }
            }
        }

        eval lappend menu_list $ml

        if {$parent_block == ""} {
            return $menu_list
        } else {
            return [walkTree $radice $parent_block node $menu_list]
        }

    }
    namespace export walkTree
}
