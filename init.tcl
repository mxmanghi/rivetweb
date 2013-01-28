# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root $website_root

package require rwlogger
package require rivetweb

apache_log_error notice "rweb_root: $rweb_root, website_root: $website_root"

::rivetweb::setup $rweb_root $website_root 

# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]
 
::rivetweb::init Scripted
::rivetweb::init XMLBase
::rivetweb::init RWDummy

set website_init [file join $website_root $::rivetweb::website_init]
if {[file exists $website_init]} {
    apache_log_error notice "running website specific initialization $website_init"
    source $website_init
}

source [file join $::rivetweb::scripts rivetweb_init.tcl]

cd $website_root
