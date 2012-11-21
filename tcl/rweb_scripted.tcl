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
        public method title {language}
        public method headline {language}
    }

    ::itcl::body RWScripted::prepare {language argsqs} {

        if {[var exists cmd]} {
            set method [var get cmd]
        } else {
            set method "run"
        }

        $this put_metadata $argsqs
        set do_method "do[string totitle $method]"
#       puts "do_method -> $do_method"
        
        $script $do_method $language $this
    }

    ::itcl::body RWScripted::print_content {language} {
        
        if {[var exists rvt]} {
            $script template $this [var get rvt]
        } else {
            $script $method $this
        }
        
    }

    ::itcl::body RWScripted::title {language} {
        return [$this metadata title]
    }

    ::itcl::body RWScripted::headline {language} {

        set headline [$this metadata headline]
        if {$headline == ""} {
            set headline [$this title $language]
        }
        return $headline

    }
}

package provide rwscripted 0.1
