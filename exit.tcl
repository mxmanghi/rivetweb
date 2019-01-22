# -- exit.tcl
#
# for symmetry with 'init.tcl' and in order to create
# a indirection and keep hidden future changes in the
# way we handle child exit


::rivet::apache_log_error notice "running the exit handler"

source [file join $rweb_root tcl rivetweb_exit.tcl]

# -- exit.tcl
