# -- rivetweb.tcl
#
# server initialization script 
#

package require Scripted
package require XMLMessage
package require rwresource

namespace eval ::rwdatas {

    ::itcl::class PBrokerTest {
        inherit UrlHandler

	public method init {args} {

            $this add_page_depend testdepend [::rivetweb::Resource [namespace current]#auto]
            $this key_class_map testdepend ::rwpage::TestDepend

	}

        public method willHandle {arglist keyvar} {
            upvar $keyvar key 

            if {[dict exists $arglist testdepend]} {
                set key testdepend
                return -code break -errorcode rw_ok 
            }

            return -code continue -errorcode rw_continue
        }
    }
}

::rivetweb::init Scripted 	 top
::rivetweb::init XMLMessage  	 top
::rivetweb::init PBrokerTest 	 top -nopkg

::rivet::apache_log_error info "URL handlers: [::rwdatas::UrlHandler::registered_handlers]"
