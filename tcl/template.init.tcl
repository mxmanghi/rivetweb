# $Id: template.init.tcl 1217 2011-10-26 15:17:40Z massimo.manghi $

namespace eval ::rivetweb { 
    set site_base     [file dirname [info script]]
    set rivet_scripts [file join $site_base tcl] 
}

apache_log_error err "Rivetweb starting with base path: $::rivetweb::site_base"
source [file join $::rivetweb::rivet_scripts rivet_init.tcl]
source [file join $::rivetweb::site_base     rivet_defs.tcl]
