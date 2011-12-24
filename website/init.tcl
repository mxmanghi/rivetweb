# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

namespace eval ::rivetweb {
    set site_base	    [pwd]
    set rivet_scripts	/home/manghi/Projects/rivetweb/tcl/
}

apache_log_error err "Rivetweb: $::rivetweb::site_base"
source [file join $::rivetweb::rivet_scripts rivet_init.tcl]

namespace eval ::rivetweb {
    set default_lang    it
#   set http_encoding   "iso-8859-1"
}
