# --  rwlogger
#
#

namespace eval ::rwlogger {

    proc log {severity msg} {
        if {[catch {
            apache_log_error $severity $msg
        }]} {
            puts stderr "\[$severity\] $msg"
        }
    }
    namespace export log
    namespace ensemble create
}

package provide rwlogger 1.0
