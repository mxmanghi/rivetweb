#
# -- after_every.tcl
#
# performing tasks to be done on exit of every request processing,
# regardless an error or abort condition occurred
#
#

    if {$::rivetweb::site_after_every_script != ""} { 
        source $::rivetweb::site_after_every_script
    }
