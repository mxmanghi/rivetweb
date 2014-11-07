#
# -- abort.tcl
#
# performing tasks to be done on exit of a request processing
#
#
    ::rivet::apache_log_error debug "running site specific abort script >$::rivetweb::site_abort_script<"

    if {$::rivetweb::site_abort_script != ""} { 
        source $::rivetweb::site_abort_script
    }

