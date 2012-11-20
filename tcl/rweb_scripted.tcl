#
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
        private variable method

        constructor {pagekey scriptcmd {pkg ""}} {RWPage::constructor $pagekey} {

            set script      $scriptcmd
            set tclpackage  $pkg
        }

        public method print_content {l}
        public method prepare {language argsqs} 
    }

    ::itcl::body RWScripted::prepare {language argsqs} {

        if {[var exists cmd]} {
            set method [var get cmd]
        } else {
            set method "run"
        }

        $this put_metadata $argsqs

    }

    ::itcl::body RWScripted::print_content {language} {
        
        if {[var exists rvt]} {
            $script template [var get rvt]
        } else {
            $script $method
        }
        
    }
}

package provide rwscripted 0.1
