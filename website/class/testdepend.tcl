# -- testdepend.tcl
#
#

namespace eval ::rwpage {

    ::itcl::class TestDepend {
        inherit RWPage

        private variable xmlbuffer

        constructor {pagekey} {RWPage::constructor $pagekey} { }

        public method init {} {
            set xmlbuffer ""
        }

        public method print_content { language } { 
            puts [::rivet::xml "test page pid: [pid]" [list div style "border: 1px solid black; padding: 1em;"] pre]
        }
    }
}

package provide testdepend 1.0
