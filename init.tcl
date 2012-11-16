# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root

package require rwlogger
package require rivetweb

apache_log_error notice "rweb_root: $rweb_root, website_root: $website_root"
apache_log_error notice "auto_path: $auto_path"

::rivetweb::setup $rweb_root $website_root 

# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]
 
::rivetweb::init Scripted
::rivetweb::init XMLBase

cd $website_root
source [file join $::rivetweb::scripts rivetweb_init.tcl]

