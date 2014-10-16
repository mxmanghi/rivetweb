package require struct::queue
package require Itcl

::itcl::class MessagePrinter {

    private variable    message_queue  [::struct::queue]
    public method       reset_message_queue {}
    public method       post_message {msg severity cssclass}
    public method       get_message {msg}

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

::itcl::body MessagePrinter::post_message {msg {severity normal} {cssclass errormessage}} {
    variable message_queue

    switch $severity {
        err {
            set msg "<div class=\"$cssclass\">$msg</div>"
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
package provide MessagePrinter 0.1
