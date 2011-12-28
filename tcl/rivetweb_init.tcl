# -- rivetweb_init.tcl
#
#
package require tdom
package require Rivet

## Rivetweb namespace encloses the whole configuration and status variables
#
#source [file join $::rivetweb::scripts rivetweb_ns.tcl]
#
## Rivetweb.tcl simply is the core of the application
#
#source [file join $::rivetweb::scripts rivetweb.tcl]

# Some preliminary setup before the application is ready to serve pages

apache_log_error notice "scripts: $::rivetweb::scripts"

source [file join $::rivetweb::scripts rivet_init.tcl]

