#
# -- rweb_menumodel.tcl
#
#

package require rwconf
package require rwlogger
package require rwlink

namespace eval ::rwmenu {

    proc create { id header {parent none} {visibility normal} } {

        if {[llength $header] == 1} {

            return  [dict create menuid         $id                                     \
                                 parent         root                                    \
                                 visibility     normal                                  \
                                 header         [dict create $::rivetweb::default_lang $header] \
                                 links          {}                                      \
                                 attributes     {}                                      \
                                 index          end                                     \
                    ]

        } else {

            return [dict create menuid $id header $header]

        }
    }
    
    proc set_parent {menumodel parent_id} {
        upvar $menumodel menum

        dict set menum parent $parent_id
    }

    proc parent {menumodel} {
        return [dict get $menumodel parent]
    }

    proc set_index {menumodel index} {
        upvar $menumodel menum
        
        if {![string is integer $index] && ($index != "end")} {
            return -code error "Wrong index parameter, must be either 'end' or integer"
        } elseif {[string is integer $index] && ($index < 0)} {
            set index "end-${index}"
        }

        dict set menum index $index
    }

    proc index {menumodel} {
        return [dict get $menumodel index]
    }

    proc addlink {menumodel linkmodel {position ""}} {
        upvar $menumodel mmodel

        set link_list [dict get $mmodel links]
        lappend link_list $linkmodel
        dict set mmodel links $link_list
    }

    proc set_attributes {menumode {attrl ""}} {
        upvar $menumodel menum

        dict set menum attributes $attrl
    }

    proc attributes {menumodel} {
        return [dict get $menumodel attributes]
    }

    proc links {menumodel} {
        return [dict get $menumodel links]
    }

    proc id {menumodel} {
        return [dict get $menumodel menuid]
    }

    namespace export links addlink create menuid
    namespace create ensemble
}

package provide rwmenu 1.0
