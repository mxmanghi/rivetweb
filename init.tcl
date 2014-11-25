# -- init.tcl
#
# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#

lappend auto_path $rweb_root $website_root

apache_log_error notice "rweb_root: $rweb_root, website_root: $website_root"

package require rwlogger
package require rivetweb

::rivetweb::setup $rweb_root $website_root 

cd $website_root

# rivetweb initialization 

set website_definitions [file join $::rivetweb::site_base site_defs.tcl]

if {[file exists $website_definitions]} { source $website_definitions }
 
::rivetweb::init Scripted
::rivetweb::init XMLBase
::rivetweb::init RWDummy

set website_init [file join $website_root $::rivetweb::website_init]
if {[file exists $website_init]} {
    apache_log_error notice "running website specific initialization $website_init ([pwd])"
    if {[catch {source $website_init} e]} {

        ::rivet::apache_log_error crit "Error running website specific initialization ($e)"
        foreach l [split $errorInfo "\n"] {
            ::rivet::apache_log_error crit $l
        }
        
    }
}

source [file join $::rivetweb::scripts rivetweb_init.tcl]
