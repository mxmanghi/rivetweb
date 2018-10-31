#
# -- rivetweb_exit.tcl
#
#+
# Children cleanup upon exit
#-
#

$::rivetweb::logger log notice "rivetweb child process [pwd] is leaving"

foreach handler [::rivetweb registered_handlers] {

    $handler destroy

}

