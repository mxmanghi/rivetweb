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
                        tcl/rweb_link.tcl       \
                        tcl/rweb_menumodel.tcl  \
                        tcl/sitemap.tcl         \
                        tcl/htmlizer.tcl        \
                        tcl/datasource/*.tcl  

