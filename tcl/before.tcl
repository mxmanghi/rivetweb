#
# $Id: before.tcl 2095 2011-12-14 17:40:52Z massimo.manghi $
#
#+
#-
#

namespace eval ::rivetweb { 

    # let's load the environment into array ::request::env

    load_env env
    set template_defs "[file rootname $env(DOCUMENT_NAME)].defs"
    if {[file exists $template_defs]} { source $template_defs }

    source [file join [file dirname [info script]] rivet_before.tcl]
    source [file join [file dirname [info script]] rivet_page.tcl]

}
