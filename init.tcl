# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root

package require rwlogger
package require rivetweb
#package require XMLBase

apache_log_error err "rweb_root: $rweb_root, website_root: $website_root"
apache_log_error err "auto_path: $auto_path"

::rivetweb::setup $rweb_root $website_root 

# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]
 
apache_log_error err "datasource: $::rivetweb::datasource"
cd $website_root
source [file join $::rivetweb::scripts rivetweb_init.tcl]

::rivetweb::init XMLBase
