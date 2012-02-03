# $Id: init.tcl 2098 2011-12-15 09:41:47Z massimo.manghi $

# this stuff must go in rivetweb's configuration, I don't see any other
# clear way to make it site specific
#
# set rweb_root /home/manghi/Projects/rivetweb/
#

lappend auto_path $::rivetweb::rivetweb_root

package require rivetweb

::rivetweb::setup $::rivetweb::rivetweb_root [file normalize [file dirname [info script]]]

# rivetweb initialization 

source [file join $::rivetweb::site_base site_defs.tcl]
source [file join $::rivetweb::scripts rivetweb_init.tcl]
::rivetweb::init $::rivetweb::datasource $::rivetweb::menusource 


