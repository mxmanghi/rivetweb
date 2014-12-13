#
# -- message_printer.tcl
#
#
#

package require struct::queue
package require Itcl

::itcl::class MessagePrinter {

    private variable    message_queue  [::struct::queue]
    public method       reset_message_queue {}
    public method       post_message {msg {severity info} {cssclass errormessage}}
    public method       get_message {msg}
    public method       print_messages {}
    public method       num_messages {} { return [$message_queue size] }
}

# -- reset_message_queue
#
#
::itcl::body MessagePrinter::reset_message_queue { } {
    variable message_queue

    $message_queue clear
}

# -- post_message
#
#

::itcl::body MessagePrinter::post_message {msg {severity info} {cssclass errormessage}} {
    variable message_queue

    switch $severity {
        err {
            set msg "<span class=\"$cssclass\">$msg</span>"
        }
        default { }
    }

    $message_queue put $msg
}

# -- get_message
#
#
::itcl::body MessagePrinter::get_message {msg} {
    upvar 1 $msg messaggio
    variable message_queue

    if {[catch {set messaggio [$message_queue get]} e]} {
        return 0
    } else {
        return 1
    }
}

::itcl::body MessagePrinter::print_messages {} {

    while {[$this get_message msg]} {
        puts "<div class=\"messageline\">$msg</div>"
    }

}

package provide MessagePrinter 0.1
