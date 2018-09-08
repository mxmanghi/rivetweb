# 

lappend auto_path .
package require UrlHandler
package require XMLBase
package require RWDummy 


source tcl/rivetweb_ns.tcl 

::rivetweb::init XMLBase
::rivetweb::init RWDummy

::rwdatas::UrlHandler::registered_handlers 

::rwdatas::UrlHandler::start_scan

