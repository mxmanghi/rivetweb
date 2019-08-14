#
# -- message_printer.tcl
#
#
#

package require struct::queue
package require Itcl

::itcl::class MessagePrinter {

    public variable msg_tag         span
    public variable css_class_error errormessage
    public variable css_class_info  infomessage
    public variable css_class_debug debumessage
    public variable css_class_undef genericmessage

    public variable msgline_tag     div
    public variable msgline_class   messageline

    private variable    message_queue [::struct::queue]

    public method       reset_message_queue {}
    public method       post_message {msg {severity info} {cssclass ""}}
    public method       get_message {msg}
    public method       print_messages {}
    public method       num_messages {} { return [$message_queue size] }
}

# -- reset_message_queue
#
#

::itcl::body MessagePrinter::reset_message_queue { } { $message_queue clear }

# -- post_message
#
#

::itcl::body MessagePrinter::post_message {msg {severity info} {cssclass ""}} {

    if { $cssclass == ""} {
        set cssclass errormessage
    }

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
    set msg 

    $message_queue put [::rivet::xml $msg [list $msg_tag class $cssclass]] 
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

# -- print_message 
#
#

::itcl::body MessagePrinter::print_messages {} {

    while {[$this get_message msg]} {
        puts [::rivet::xml $msg [list div class $msgline_class]]
    }

}

package provide MessagePrinter 1.0

