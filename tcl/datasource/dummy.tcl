#
# -- dummy.tcl
#
# dummy datasource for pages generated on the fly
#
#

package require Itcl
package require rwconf
package require rwlogger
package require Datasource
package require rwbasicpage

namespace eval ::rwdatas {

    ::itcl::class RWDummy { 
        inherit Datasource

        set messages [dict create   unknown_error_condition "Unknwon error condition" \
                                    page_not_found_error    "Page not found"]

        public method name {} { return "Dummy" }
    }

    public method willHandle {arglist keyvar} { 
        upvar $keyvar key 

        set key page_not_found

        return -code break -errorcode rw_ok 
    }

    public method fetchData {key reassigned_key} {
        upvar $reassigned_key rkey

        if {[dict exists $key]} {

        } else {

        }
    }

# -- rivetwebPage
#
# central hub method to create rivetweb specific 
# messages
#

    public proc rivetwebPage {page_key} {

    }

}

package provide RWDummy 1.1
