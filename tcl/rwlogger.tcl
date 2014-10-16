#
# --  rwlogger
#
# Attempt to outline a logging utility for rivetweb based applications
#

namespace eval ::rwlogger {

    proc log {severity msg} {

        set msg "\[[pid]\] $msg"

        if {[catch { ::rivet::apache_log_error $severity $msg }]} {
            puts stderr "\[$severity\] $msg"
        }
    }
    namespace export log
    namespace ensemble create
}

package provide rwlogger 1.0
