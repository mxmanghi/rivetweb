# -- rivetweb.tcl
#
# server initialization script 
#

package require Scripted
package require XMLMessage

::rivetweb::init Scripted 	top
::rivetweb::init XMLMessage top

::rivet::apache_log_error info "URL handlers: [::rwdatas::UrlHandler::registered_handlers]"
