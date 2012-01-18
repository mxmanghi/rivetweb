# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

set rweb_root /home/manghi/Projects/rivetweb-sf/

lappend auto_path  $rweb_root
package require rivetweb

::rivetweb::setup $rweb_root [file normalize [file dirname [info script]]]


# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]
source [file join $::rivetweb::scripts rivetweb_init.tcl]
::rivetweb::init XMLData XMLMenu


