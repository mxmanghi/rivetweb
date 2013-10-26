#
# -- after.tcl
#
# performing tasks to be done on exit of a request processing
#
#

    if {$::rivetweb::site_after_script != ""} { 
        source $::rivetweb::site_after_script
    }
