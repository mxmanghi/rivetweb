#
# -- urlcomposer.tcl
#
# Implementation of a URL composer to be called by ::rivetweb::composeUrl
#

namespace eval ::rivetweb {

    ::itcl::class UrlComposer {

        private variable rewrite_par
        
        # shouldn't they be declared as 'private common' instead?

        private variable sticky_args                {language reset template $rewrite_par lang}
        private variable conditioned_sticky_args    {$rewrite_par}

        constructor {rewrite_par_def} {
            set rewrite_par                 $rewrite_par_def
            set sticky_args                 [subst $sticky_args]
            set conditioned_sticky_args     [subst $conditioned_sticky_args]
        }

        # taken from the Tcl'er wiki (http://wiki.tcl.tk/15659)

        private method clean_list {target args} {
            set res $target
            foreach unwant $args {
              # suchenwirth idea
              set res [lsearch -all -inline -not -exact $res $unwant ]
            }
            return $res
        }

        public method get_sticky_args {} { return $sticky_args }

        public method add_sticky_args {new_sticky_args} {
            lappend sticky_args {*}$new_sticky_args

            return $sticky_args
        }

        public method add_conditioned_sticky_args {conditioned_sa} {
            lappend conditioned_sticky_args {*}$conditioned_sa
        }

        public method get_rewrite_par {} { return $rewrite_par }

        public method merge_sticky_args {urlargs {current_url_args ""} {rewrite_flag 0}} {

            set url_arguments [dict create {*}$urlargs]

            # we skip ::rivetweb::rewrite_par (and any other conditioned sticky arg) 
            # if we are alredy rewriting links
            # as the whole point of link rewriting is charging mod_rewrite rules 
            # to figure it out

            if {$rewrite_flag} {
                set sas [$this clean_list $sticky_args {*}$conditioned_sticky_args]
            } else {
                set sas $sticky_args
            }

            foreach sticky_arg $sas {

                #if {$keep_rewrite_par && \
                #    ($sticky_arg == $rewrite_par)} { continue }

                if { [dict exists $current_url_args $sticky_arg] && \
                    ![dict exists $urlargs $sticky_arg]} {

                    dict set urlargs $sticky_arg [dict get $current_url_args $sticky_arg]

                }
            }

            return $urlargs
        }

        public method strip_sticky_args {urlargs} {
            set urlargs_d [dict create {*}$urlargs]
            return [dict remove $urlargs_d {*}$sticky_args]
        }

        # -- compose_url
        #
        #   arguments: 
        #
        #       arglist:        dictionary of argument - value pairs
        #       current_args:   current URL arguments
        #       rewrite_link:   flag mod_rewrite is controlling the rewrite process
        #                       "" - no rewrite done
        #

        public method compose_url {arglist current_url_args {rewrite_code ""}} {

            if {[string match $rewrite_code ""]} {
                set rewrite_links 0
                set rewritten_url [::rivetweb::scriptName]
            } else {
                set rewrite_links 1
                ::rivetweb::rewrite_url $rewrite_code [::rivetweb::scriptName] arglist rewritten_url
            }

            array set argsmap {}
            set hash ""
            while {[llength $arglist]} {
                set arglist [lassign $arglist param value]
                if {$param == "#"} { 
                    set hash $value 
                    continue
                }

                set argsmap($param) [::rivet::escape_string $value]
            }

            set arglist [array get argsmap]

            # finally we blend sticky arguments into the arguments 

            set arglist [$this merge_sticky_args $arglist $current_url_args $rewrite_links]
            set urlargs {}

            ::rivet::apache_log_error debug "URL $rewritten_url -> $arglist"
            if {[llength $arglist]} {

                while {[llength $arglist]} {
                    set arglist [lassign $arglist param value]
                    lappend urlargs "${param}=${value}"
                }
                set final_url "${rewritten_url}?[join $urlargs "&"]"

            } else {

                set final_url $rewritten_url

            }

            if {$hash != ""} {append final_url "#$hash" }

            return $final_url
        }

    }

}

package provide urlcomposer 1.0
