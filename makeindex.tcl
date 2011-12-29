#!/usr/bin/tclsh
#
# -- makeIndex.tcl
#
#
# Rivetweb pkgIndex.tcl builder
#

pkg_mkIndex -verbose . tcl/rivetweb.tcl tcl/rivetweb_ns.tcl tcl/terminal.tcl tcl/datasource/*.tcl 

