#
# -- rweb_menumodel.tcl
#
# Model for menu data.
#
#

package require rwconf
package require rwlogger
package require rwlink

namespace eval ::rwmenu {

# -- create <id> ?<parent> none? ?<visibility> normal?
#
# 

    proc create { id {parent none} {visibility normal} } {

        return  [dict create menuid         $id           \
                             parent         $parent       \
                             visibility     $visibility   \
                             title          [dict create] \
                             links          {}            \
                             attributes     {}      \
                             index          end     \
                ]

    }

# -- title <menuobj> ?language?. 
#
# Accessor to the title to be printed in the menu. If
# no ?language? parameter is passed then the title
# for the default language is returned

    proc title {menuobj {language ""}} {
        if {[string length $language] == 0} {
            set language $::rivetweb::default_lang
        }

        if {[dict exists $menuobj title $language]} {
            return [dict get $menuobj title $language]
        } else {
            return [dict get $menuobj title $::rivetweb::default_lang]
        }
    }

# -- parent, index, attributes
# 
# specific accessors for structural information of a menuobj. 
#
#    - parent: id of the parent. If a menuobj has no parent 
#      it will be put as root of menu hirarchy
#    - index: not used
#    - attributes: not handled. It's supposed to return a 
#      list of HTML attribute-value pairs.
#

    proc parent {menumodel} {
        return [dict get $menumodel parent]
    }

    proc index {menumodel} {
        return [dict get $menumodel index]
    }

    proc attributes {menumodel} {
        return [dict get $menumodel attributes]
    }

# -- peek: generic accessor for a custom parameter
# associated to the menuobj. if the attribute 'param'
# is not existing in the object an error is raised

    proc peek {menuobj param} {
        return [dict get $menuobj $param]
    }

# -- assign: multipurpose method to assign various parameters
#

    proc assign {parameter menuobj pvalue args} {
        upvar $menuobj menu_o

        switch $parameter {

            attributes {
                dict set menu_o attributes $pvalue
            }
            parent {
                dict set menu_o parent $pvalue
            }
            title {
                set language [lindex $args 0]

# the 'title' parameter expects the argument to be a dictionary

                dict set menu_o title $language $pvalue
                
                if {![dict exists $menu_o title $::rivetweb::default_lang]} {
                    dict set menu_o title $::rivetweb::default_lang $pvalue
                }
            }
            index {
                set index $pvalue             

                if {![string is integer $index] && ($index != "end")} {
                    return -code error \
                        "Wrong index parameter, must be either 'end' or integer"
                } elseif {[string is integer $index] && ($index < 0)} {
                    set index "end-${index}"
                }
                dict set menu_o index $index
            }
            default {
                $::rivetweb::logger log err "unmanaged parameter $parameter"
            }
        }

    }

# --add_link
#
# Adds a link object to the menu
#

    proc add_link {menuobj linkmodel {position ""}} {
        upvar $menuobj  menu_o

        set     link_list [dict get $menu_o links]
        lappend link_list $linkmodel
        dict set menu_o links $link_list
    }

# -- links
#
#
    proc links {menuobj} {
        return [dict get $menuobj links]
    }

# -- id 
#
#
    proc id {menuobj} {
        return [dict get $menuobj menuid]
    }

    namespace export   *
    namespace ensemble create
}

package provide rwmenu 1.0
