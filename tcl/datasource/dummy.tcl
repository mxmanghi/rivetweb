#
# -- dummy.tcl
#
# dummy datasource for pages generated on the fly
#
#

package require rwconf
package require rwlogger

namespace eval ::RWDummy {

# -- init
#
#
    proc init {args} { }
    proc willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
    proc fetchData { } { return "" }
    proc is_stale {key timereference} { return false }
    proc menu_list {page} { return [dict create] }

    namespace export *
    namespace ensemble create
}

package provide RWDummy 1.0
