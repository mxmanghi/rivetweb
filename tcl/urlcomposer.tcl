#
# -- urlcomposer.tcl
#
# Implementation of a URL composer to be called by ::rivetweb::composeUrl
#

namespace eval ::rivetweb {

    ::itcl::class UrlComposer {

        private variable immutable_sticky_args {language reset template $rewrite_par lang}

        # should be a 'private common' instead?

        private variable sticky_args
        private variable rewrite_par    rwrw


        constructor {} {
            set sticky_args [subst $immutable_sticky_args]
        }

        public method get_sticky_args {} { return $sticky_args }

        public method add_sticky_arg {new_sticky_arg} {
            lappend immutable_sticky_args $new_sticky_arg
            set sticky_args [subst $immutable_sticky_args]
            return $sticky_args
        }

        private method recreate_sticky_args_list {} {
            set sticky_args [subst $immutable_sticky_args]
        }

        public method set_rewrite_par {rw_par} {
            set rewrite_par $rw_par
            $this recreate_sticky_args_list
        }

        public method get_rewrite_par {} { return $rewrite_par }

        public method merge_sticky_args {urlargs {current_url_args ""} {keep_rewrite_par 0}} {

            set url_arguments [dict create {*}$urlargs]

            foreach sticky_arg $sticky_args {

                # we skip ::rivetweb::rewrite_par if we are alredy rewriting links
                # as the whole point of link rewriting is charging mod_rewrite rules 
                # to figure it out

                if {$keep_rewrite_par && \
                    ($sticky_arg == $rewrite_par)} { continue }

                if { [dict exists $current_url_args $sticky_arg] & \
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

            set rewrite_links [string match $rewrite_code ""]

            if {$rewrite_links} {

                set rwcode $rewrite_code
                ::rivetweb::rewrite_url $rewrite_code [::rivetweb::scriptName] arglist rewritten_url

            } else {

                set rewritten_url [::rivetweb::scriptName]

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

