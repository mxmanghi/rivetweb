# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

namespace eval ::rivetweb {
    set site_base	    [pwd]
    set rivet_scripts	[file join [file dirname [info script]] .. tcl]
}

apache_log_error err "Rivetweb: $::rivetweb::site_base"
source [file join $::rivetweb::rivet_scripts rivet_init.tcl]
source [file join $::rivetweb::site_base rivet_defs.tcl]
