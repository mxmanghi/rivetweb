# 
# $Id: makepagehtml.tcl 2094 2011-12-14 16:25:05Z massimo.manghi $
#
#+
# rivetweb procedure for handling the DOM of a page and generating
# XHTML output. These procedure are defined within the ::rivetweb 
# namespace
#-
#
# Changelog:
#
# 11 Nov 2011:  This file is sourced by rivet_page.tcl within
#               the ::rivetweb namespace
#


# -- xmlPostProcessing
# 
# This procedure implements a key feature of Rivetweb, since
# it catches every element in a page and special elements
# are elaborated and rewritten in the DOM.
# 
# The whole process is largely and awfully suboptimal though
# and it should be matter of reckoning and careful pondering
# for a deep rewriting
# 
#  Arguments: 
#    - xmlDoc: tdom object representing the page
#
#  Returned value:
#    - the tdom object reelaborated.
#
# The functionalities of the procedure have been handed to
# the hooks mechanism
# 

#proc xmlPostProcessing {xmlDoc} { return $xmlDoc }
#namespace export xmlPostProcessing
# vi:shiftwidth=4:softtabstop=4:
