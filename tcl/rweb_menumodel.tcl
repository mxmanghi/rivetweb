#
# -- rweb_menumodel.tcl
#
#

package require rwconf
package require rwlogger
package require rwlink

namespace eval ::rwmenu {

    proc create { id {parent none} {visibility normal} } {

        return  [dict create menuid         $id     \
                             parent         root    \
                             visibility     normal  \
                             title         [dict create] \
                             links          {}      \
                             attributes     {}      \
                             index          end     \
                ]

    }

    proc title {menuobj language} {
        return [dict get $menuobj title $language]
    }

    proc parent {menumodel} {
        return [dict get $menumodel parent]
    }

    proc index {menumodel} {
        return [dict get $menumodel index]
    }

    proc attributes {menumodel} {
        return [dict get $menumodel attributes]
    }

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

            }
            index {
                set index $pvalue             

                if {![string is integer $index] && ($index != "end")} {
                    return -code error "Wrong index parameter, must be either 'end' or integer"
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

    proc add_link {menumodel linkmodel {position ""}} {
        upvar $menumodel    mmodel

        set     link_list [dict get $mmodel links]
        lappend link_list $linkmodel
        dict set mmodel links $link_list
    }

    proc links {menumodel} {
        return [dict get $menumodel links]
    }

    proc id {menumodel} {
        puts "--->$menumodel<----"
        return [dict get $menumodel menuid]
    }

    namespace export links add_link create menuid assign id parent index
    namespace ensemble create
}

package provide rwmenu 1.0
