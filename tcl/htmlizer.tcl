# -- htmlizer.tcl
#
# ::htmlizer ensemble that is meant to collect method
# to transform different objects in their HTML representation
#  

namespace eval ::htmlizer {

# -- html_menu, a procedure whose specialization is 
# transforming a menuobj into an
# HTML menu. menustruct is a even lenght list of attribute
# value pairs controlling the markup
#
    proc html_menu { menuobj language menustruct} {

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

        set menumodel   $::rivetweb::menumodel
        set linkmodel   $::rivetweb::linkmodel

# we create the HTML menu dom

        set menudom [dom createDocument $menu_tag]
        set htmlmenu_o [$menudom documentElement]

        eval $htmlmenu_o setAttribute id [$menumodel id $menuobj]       
        if {[string length $menu_class]} { 
            eval $htmlmenu_o setAttribute class $menu_class 
        }

# we set aside the handling of the 'notitle' attribute

# let's get the title to be printed as header for the menu

        set menu_title [$menumodel title $menuobj $language]
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

# and finally we create a node for each link in the menu
        
        set links [$menumodel links $menuobj]
        foreach link $links {
            set item_o [$menudom createElement $item_tag]
            if {[string length $link_class]} {
                $item_o setAttribute class $link_class
            }
            $item_container_o appendChild $item_o

            set link_o [$menudom createElement a]
            $item_o appendChild $link_o

            set link_text [$linkmodel link_text $link $language]
            set link_info [$linkmodel link_info $link $language]
            set link_target [$linkmodel get_attribute $link target]
            set link_ref  [$linkmodel reference $link]

            set text_o [$menudom createTextNode $link_text]
            $link_o appendChild $text_o

            if {[string length $link_info]} {
                $link_o setAttribute title $link_info
            }
            if {[string length $link_target]} {
                $link_o setAttribute target $link_target
            }

            switch [$linkmodel type $link] {
    
                internal {
                    $link_o setAttribute \
                        href [::rivetweb::makeUrl $link_ref]
                }
                external {
                    $link_o setAttribute href $link_ref
                }
                local {
                    $link_o setAttribute href \
                        [file join $::rivetweb::local_pages $link_ref]
                    
                }

            }
        }

        set htmlMenu [$menudom asXML]
        $menudom delete
        return $htmlMenu  
    }
    namespace export *
    namespace ensemble create
}
package provide htmlizer 1.0
