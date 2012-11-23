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
        private variable do_method

        constructor {pagekey scriptcmd {pkg ""}} {RWPage::constructor $pagekey} {

            set script      $scriptcmd
            set tclpackage  $pkg

        }

        public method print_content {l}
        public method prepare {language argsqs} 
        public method title {language {titletxt ""}}
        public method headline {language}
    }

    ::itcl::body RWScripted::prepare {language argsqs} {
        RWPage::prepare $language $argsqs

        if {[$this recall cmd cmd]} {
            set method $cmd
        } else {
            set method "run"
        }

        set do_method "do[string totitle $method]"
        puts "<div style=\"background: #aaf\">do_method -> $do_method</div>"
        
        $script $do_method $language $this
    }

    ::itcl::body RWScripted::print_content {language} {
        
        if {[$this recall rvt rvtfile]} {
            $script template $this $rvtfile
        } elseif {[$this recall tcl method]} {
            $script $method $language $this
        }
        
    }

    ::itcl::body RWScripted::title {language {titletxt ""}} {

        if {$titletxt == ""} {
            return [$this metadata title]
        } else {
            $this add_metadata title $titletxt
        }

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
