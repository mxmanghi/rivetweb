# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

namespace eval ::rivetweb { 
    set site_base   [file dirname [info script]] 
    set scripts     /home/manghi/Projects/rivetweb-sf/tcl/
}
lappend auto_path $::rivetweb::scripts

apache_log_error info "starting rivetweb for website at $::rivetweb::site_base"

# rivetweb initialization 

source [file join $::rivetweb::scripts rivetweb_init.tcl]
source [file join $::rivetweb::site_base site_defs.tcl]
