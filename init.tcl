# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#
# set rweb_root /home/manghi/Projects/rivetweb/
#

#set rweb_root [file normalize [file join ..]]
lappend auto_path $rweb_root

apache_log_error debug "rweb_root: $rweb_root, website_root: $website_root"
apache_log_error debug "auto_path: $auto_path"

package require rwlogger
package require rivetweb

#::rivetweb::setup $rweb_root [file normalize [file dirname [info script]]]
::rivetweb::setup $rweb_root $website_root 

# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]

cd $website_root
source [file join $::rivetweb::scripts rivetweb_init.tcl]

::rivetweb::init XMLBase
