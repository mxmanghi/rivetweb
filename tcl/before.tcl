#
# $Id: before.tcl 2095 2011-12-14 17:40:52Z massimo.manghi $
#
#+
#-
#

namespace eval ::rivetweb { 

    # let's load the environment into array ::request::env

    load_env env
#   set template_defs "[file rootname $env(DOCUMENT_NAME)].defs"
#   if {[file exists $template_defs]} { source $template_defs }

    apache_log_error notice "running tcl/before.tcl"

    set rivet_before [file join $scripts rivet_before.tcl]
    set rivet_page   [file join $scripts rivet_page.tcl]

    if {![info exists rivet_before_mtime]} {
        set rivet_before_mtime [file mtime $rivet_before]
    }
    if {![info exists rivet_page_mtime]} {
        set rivet_page_mtime [file mtime $rivet_page]
    }

    source [file join $scripts rivet_before.tcl]
    source [file join $scripts rivet_page.tcl]
}
