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

# before we check for specific methods to be run we run a generic
# 'init' method with common initialization for all methods.

        $this clear_metadata
        if {[catch {$script init $language $this} e opts]} {


    # first of all we run the 'handler' method that could have been 
    # superseded in the application subclasses of ScriptBase

            $script handler $opts

            if {[dict exists $opts -errorcode]} {
                set errorCode [dict get $opts -errorcode]
                if {![$::rivetweb::rwebdb check $errorCode]} {

                    set pobj [::rwpage::RWStatic ::#auto $errorCode]
                    $pobj set_pagetext $::rivetweb::default_lang "<b>$e</b> (code $errorCode): [escape_sgml_chars $opts]"
                    $pobj add_metadata header "[string range $e 0 20]..."
                    $pobj add_metadata title  "[string range $e 0 20]..."
                    $::rivetweb::rwebdb store $errorCode $pobj ::RWDummy

                } else {

                    set pobj [$::rivetweb::rwebdb fetch $errorCode]
                    $pobj set_pagetext $::rivetweb::default_lang "<b>$e</b>: $opts"
                    $pobj add_metadata header "[string range $e 0 20]..."
                    $pobj add_metadata title  "[string range $e 0 20]..."

                }
            } else {

            }

            return $pobj
        }

        if {[$this recall cmd cmd]} {
            set method $cmd
        } else {
            set method "run"
        }

        set do_method "do[string totitle $method]"
        puts "<div style=\"background: #aaf\">do_method -&gt; $do_method</div>"
        
        if {[catch {$script $do_method $language $this} e opts]} {
            set errorCode [dict get $opts -errorcode]
            if {![$::rivetweb::rwebdb check $errorCode]} {

                set pobj [::rwpage::RWStatic ::#auto $errorCode]
                $pobj set_pagetext $::rivetweb::default_lang "<b>$e</b> (code $errorCode): $opts"
                $pobj add_metadata header "[string range $e 0 20]..."
                $pobj add_metadata title  "[string range $e 0 20]..."
                $::rivetweb::rwebdb store $errorCode $pobj ::RWDummy

            } else {

                set pobj [$::rivetweb::rwebdb fetch $errorCode]
                $pobj set_pagetext $::rivetweb::default_lang "<b>$e</b> $opts"
                $pobj add_metadata header "[string range $e 0 20]..."
                $pobj add_metadata title  "[string range $e 0 20]..."

            }

            return $pobj

        } else {

            return $this

        }

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
