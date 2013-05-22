#
# -- root class for databases
#
#
# abstract class defining the common interface for all datasources
#

package require Itcl
package require rwconf
package require rwlogger


namespace eval ::rwdatasource {

    ::itcl::class Datasource {

        public method init {args} {}
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData { } { return "" }
        public method is_stale {key timereference} { return false }
        public method menu_list {page} { return [dict create] }

    }
}

