#
# -- rivetweb_exit.tcl
#
#+
# Children cleanup upon exit
#-
#

# waiting for a ::rivet::thread_id command in order to have a thread
# specific way to log this termination

#$::rivetweb::logger log notice "rivetweb thread [pid] is leaving"

foreach handler [::rivetweb registered_handlers] {

    $handler destroy

}

