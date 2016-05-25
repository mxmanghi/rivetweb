# -- rweb_message.tcl
#
# RWMessage is a class to producing message pages 
# to show various error conditions in rivetweb and
# application level collaborating classes
#

package require Itcl
package require rwpage

namespace eval ::rwpage {

    ::itcl::class RWBasicPage {
        inherit RWPage

        private variable pagetext
        private variable rootelement

        constructor {pagekey {message_text ""} {rootel "p"}} {RWPage::constructor $pagekey} {
            set pagetext [dict create $::rivetweb::default_lang $message_text]
            set rootelement $rootel
        }

        public method pagetext_append {$language $t} {
            dict append pagetext $language $t
        }

        public method pagetext {language {page_text ""} } {

            if {$page_text != ""} {
                $this pagetext_append $language $page_text
            }

            if {[dict exists $pagetext $language]} {
                return [dict get $pagetext $language]
            } else {
                return ""
            }

        }

        public method print_content {language} {
            puts -nonewline [::rivet::xml [$this pagetext $language] $rootelement]
        }

    }

}
package provide rwbasicpage 0.1

