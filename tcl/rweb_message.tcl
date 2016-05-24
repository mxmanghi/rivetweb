# -- rweb_message.tcl
#
# RWMessage is a class to producing message pages 
# to show various error conditions in rivetweb and
# application level collaborating classes
#

package require Itcl
package require rwpage

namespace eval ::rwpage {

    ::itcl::class RWMessage {
        inherit RWPage

        private variable pagetext

        constructor {pagekey} {RWPage::constructor $pagekey} {
            set pagetext [dict create $::rivetweb::default_lang ""]
        }

        public method set_pagetext {language page_text {rootel "p"}} {
            dict set pagetext $language [::rivet::xml $page_text $rootel]
        }

        public method print_content {language} {
            if {[dict exists $pagetext $language]} {
                puts -nonewline [dict get $pagetext $language]
            } else {
                puts -nonewline ""
            }
        }

    }

}
package provide rwmessage 0.1

