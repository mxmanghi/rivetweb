# -- rivetweb_init.tcl
#
#
package require tdom
package require Rivet

# Some preliminary setup before the application is ready to serve pages

apache_log_error notice "running Rivetweb scripts at: $::rivetweb::scripts"

source [file join $::rivetweb::scripts rivet_init.tcl]

