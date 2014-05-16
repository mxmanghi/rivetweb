# -- htmlizer.tcl
#
# ::htmlizer ensemble that is meant to collect method
# to transform different objects in their HTML representation
#  

package require tdom

namespace eval ::htmlizer {

# -- html_menu, a procedure whose specialization is 
# transforming a menuobj into an HTML menu. menustruct is a even lenght list
# of attribute value pairs controlling the markup
#
# html_menu takes a tdom object command from the menu dom and generates the html
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
#   Arguments: 
#
# - menuObj: tdom object representing the menu to be printed
# - language: language code
# - menu_struct: list of attr-value pairs controlling the markup of the menu
#
#	  * Element 0: html element tag that will encompass the whole menu (default: div)
#	  * Element 1: css class for the element (default: staticmenu)
#
# - title_html: 2 element list
#
#		* Element 0: html element tag enclosing the menu title (def: div)
#		* Element 1: css class for the element (default: menuheader)
#
# - it_cont_html: 2 element list
#
#		* Element 0: html element tag enclosing the menu items (def: div)
#		* Element 1: css class for the element (default: itemcontainer)
#
# - item_html: 2 element list
#
#		* Element 0: html element delimiting an item (def: span)
#		* Element 1: css class for the element (default: navitem)
#
#   Returned value:
#
#	menu in XHTML 
#  
    proc html_menu { menuobj language menustruct } {

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

        set linkmodel       $::rivetweb::linkmodel

# we create the HTML menu dom

        set menudom [dom createDocument $menu_tag]
        set htmlmenu_o [$menudom documentElement]

# setting id and class attributes (if defined)

        set menuid [$menuobj id]
        if {[string length $menuid]} {
            $htmlmenu_o setAttribute id [$menuobj id]
        }

        if {[string length $menu_class]} { 
            $htmlmenu_o setAttribute class $menu_class 
        }

        set cssclass [$menuobj peek cssclass]
        if {[string length $cssclass]} {
            $htmlmenu_o setAttribute class $cssclass 
        }

# we set aside the handling of the 'notitle' attribute
# let's get the title to be printed as header for the menu

        set menu_title [$menuobj title $language]
        if {[string length $menu_title] > 0} {

            set title_dom [$menudom createElement $title_tag]
            if {[string length $title_class]} {
                $title_dom setAttribute class $title_class 
            }
            $htmlmenu_o appendChild $title_dom
            set text_o [$menudom createTextNode $menu_title]
            $title_dom appendChild $text_o

        }

# we now create the element which to contain the menu items

        set item_container_o [$menudom createElement $it_cont_tag]
        if {[string length $it_cont_class]} {
            $item_container_o setAttribute class $it_cont_class
        }
        $htmlmenu_o appendChild $item_container_o

# and finally we create a node for each link in the menu.
# We scan each link in the menu and gather the information
# stored in it filling a link_o (domeNode) object instance
#
        set links [$menuobj links]
        foreach link $links {

            set ds    [$linkmodel owner $link]
            set link  [$ds to_url $link]

            set item_o [$menudom createElement $item_tag]
            if {[string length $link_class]} {
                $item_o setAttribute class $link_class
            }
            $item_container_o appendChild $item_o

            set link_o [$menudom createElement a]
            $item_o appendChild $link_o

            set link_text [$linkmodel link_text $link $language]
            set link_info [$linkmodel link_info $link $language]
            #set link_target [$linkmodel get_attribute $link target]
            set link_ref  [$linkmodel reference $link]

            set text_o [$menudom createTextNode $link_text]
            $link_o appendChild $text_o

            if {[string length $link_info]} {
                $link_o setAttribute title $link_info
            }

# this should set also href as it's part of the link object attributes

            if {[dict exists $link attributes]} {
                $link_o setAttribute {*}[dict get $link attributes]
            }

            #::rivet::html "assigning attributes [dict get $link attributes] to link" div b 
        }

        set htmlMenu [$menudom asXML]
        $menudom delete
        return $htmlMenu  
    }
    namespace export *
    namespace ensemble create
}
package provide htmlizer 1.0
