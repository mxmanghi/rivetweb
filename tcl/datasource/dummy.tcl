#
# -- dummy.tcl
#
# dummy datasource for pages generated on the fly
#
#

package require rwconf
package require rwlogger
package require Datasource

namespace eval ::rwdatas {

    ::itcl:class RWDummy { 
        inherit Datasource

        public method name {} { return "Dummy" }
    }

}

package provide RWDummy 1.1
