# -- rweb_scripted
#
# page model for a generic scripted page
#
#

package require Itcl
package require rwpage

namespace eval ::rwpage {

    ::itcl::class RWScripted {
        inherit RWPage

        private variable script
        private variable tclpackage

        constructor {pagekey scriptcmd {pkg ""}} {RWPage::constructor $pagekey} {

            set script      $scriptcmd
            set tclpackage  $pkg
        }

        public method print_content {l}
    }

    ::itcl::body RWScripted::print_content {language} {
        
        {*}$script run
        
    }
}

package provide rwscripted 0.1
