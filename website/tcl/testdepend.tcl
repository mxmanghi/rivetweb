# -- testdepend.tcl
#
#

namespace eval ::rwpage {

    ::itcl::class TestDepend {
        inherit RWPage

        private variable xmlbuffer

        public method init {} {
            set xmlbuffer ""
        }

        public method print_content { language } { 
            puts $xmlbuffer
        }
    }
}

package provide testdepend 1.0
