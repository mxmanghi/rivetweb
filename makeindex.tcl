#!/usr/bin/tclsh
#
# -- makeIndex.tcl
#
#
# Rivetweb pkgIndex.tcl builder
#

pkg_mkIndex -verbose .  tcl/rivetweb.tcl        \
                        tcl/rwlogger.tcl        \
                        tcl/rivetweb_ns.tcl     \
                        tcl/terminal.tcl        \
                        tcl/rweb_coredb.tcl     \
                        tcl/rweb_pmodel.tcl     \
                        tcl/datasource/*.tcl  

