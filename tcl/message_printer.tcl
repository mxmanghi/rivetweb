#
# -- message_printer.tcl
#
#
# message queue storage and HTML generation
#
# an instance of this class has to be initialized
# when a request processing begins and works as a
# queue of messages (holding also their severity)
#

package require struct::queue
package require Itcl

::itcl::class MessagePrinter {

    public variable msg_tag         span
    public variable css_class_error errormessage
    public variable css_class_info  infomessage
    public variable css_class_debug debugmessage
    public variable css_class_undef genericmessage

    public variable msgline_tag     div
    public variable msgline_class   messageline

    private variable message_queue [::struct::queue]

    public method reset_message_queue {}
    public method post_message {msg {severity info}}
    public method get_message {msg}
    public method html_messages {}
    public method pop_messages {}
    public method print_messages {}
    public method num_messages {} { return [$message_queue size] }

}

# -- reset_message_queue
#
#

::itcl::body MessagePrinter::reset_message_queue { } { $message_queue clear }

# -- post_message
#
#

::itcl::body MessagePrinter::post_message {msg {severity info}} {

    $message_queue put [list $msg $severity]

}

# -- get_message
#
#

::itcl::body MessagePrinter::get_message {msg} {
    upvar 1 $msg messaggio

    if {[catch {set messaggio [$message_queue get]} e]} {
        return 0
    } else {
        return 1
    }
}

::itcl::body MessagePrinter::pop_messages {} {

    set lmessage ""
    while {[$this get_message msg]} {
        lappend lmessage $msg
    }
    return $lmessage

}

::itcl::body MessagePrinter::html_messages {} {

    set cssclass errormessage
    set html ""
    while {[$this get_message msg_l]} {

        lassign $msg_l msg severity
        switch $severity {
            info {
                set cssclass $css_class_info
            }
            debug {
                set cssclass $css_class_debug
            }
            err {
                set cssclass $css_class_error
            }
            default { 
                set cssclass $css_class_undef
            }
        }
        append html [::rivet::xml $msg [list $msgline_tag class $msgline_class]\
                                       [list $msg_tag class $cssclass]]
    }
    return $html
}

# -- print_message 
#
#

::itcl::body MessagePrinter::print_messages {} {

    puts [$this html_messages]

}

package provide MessagePrinter 1.1

