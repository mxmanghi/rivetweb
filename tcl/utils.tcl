# -- utils.tcl
#
#

namespace eval ::rivetweb::utils {

    proc error_info_formatting { ei_d } {
    
        set html_s "<pre>"
        dict for {k v} $ei_d {
            append html_s [format "%-20s %s\n" $k $v]
        }
        append html_s "</pre>"
    }

    namespace ensemble create
}

package provide rwutils 1.0 
