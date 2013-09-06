#
# -- linkmodel.tcl
#
# Itcl based linkmodel. To preserve the interface a set
# of common (proc) methods will be defined
#
#

package require Itcl

namespace eval ::rwmenu {

    ::itcl::class RWLink {

        constructor {

        }

    }




    proc create {link_type reference link_text link_args {link_info ""}} {

    }

    proc add_text {linkmodel language link_text {link_info ""}} {

    }
    namespace export create add_text 

    proc set_attribute {linkobj attribute_list} {

    }
    namespace export set_attribute

    proc get_attribute {linkobj attribute} {

    }
    namespace export get_attribute


    proc link_text {linkmodel {language ""}} {

    }
    namespace export link_text

    proc link_info {linkmodel {language ""}} {

    }
    namespace export link_info

    proc type {linkmodel} {

    }
    namespace export type

    proc reference {linkobj} {

    }
    namespace export reference

    proc arguments {linkobj} {

    }
    namespace export arguments
    

    namespace ensemble create
}

package provide rwmenu 2.0
