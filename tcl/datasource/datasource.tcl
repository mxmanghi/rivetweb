#
# -- root class for databases
#
#
# abstract class defining the common interface for all datasources
#

package require Itcl
package require rwconf
package require rwlogger

namespace eval ::rwdatas {

    ::itcl::class Datasource {

        public method init {args} {}
        public method willHandle {arglist keyvar} { return -code break -errorcode rw_ok }
        public method fetchData {key reassigned_key}
        public method is_stale {key timereference} { return false }
        public method synchData {key data_dict} {}
        public method dispose {key} {}
        public method has_updates {} { return false }
        public method load_sitemap {sitemap_mgr {ctx ""}}
        public method menu_list {page} { return [dict create] }
        public method name {} { return "Datasource" }

    }
}

package provide Datasource 1.0

