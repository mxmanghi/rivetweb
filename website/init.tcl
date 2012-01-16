# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

set rweb_root /home/manghi/Projects/rivetweb

lappend auto_path  $rweb_root
package require rivetweb

::rivetweb::init $rweb_root [file dirname [info script]] XMLData XMLMenu

if {[info exists ::rivetweb::apache_running]} {
    apache_log_error info "starting rivetweb for website at $::rivetweb::site_base"
}

# rivetweb initialization 

source [file join $::rivetweb::scripts rivetweb_init.tcl]
source [file join $::rivetweb::site_base site_defs.tcl]
