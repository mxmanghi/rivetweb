# -- rivetweb.tcl
#
# server initialization script 
#

package require UrlHandler
package require XMLMessage

::rivetweb::init Scripted top
::rivetweb::init XMLMessage top

::rivet::apache_log_error info "URL handlers: $::rivetweb::datasources"
