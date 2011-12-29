# -- terminal.tcl
#
# terminal io for configuration procedures 
#

namespace eval ::rwterm {

    proc prompt {termch prompt_line} {
        puts -nonewline $termch $prompt_line
        flush $termch
    }

    proc get_line {ch prompt_line input_line} {
        upvar $input_line line    

        prompt stdout $prompt_line
        return [gets $ch line]

    }

    proc read_input_line {ch prompt_line} {

        while {![eof $ch]} {
            if {([get_line stdin $prompt_line linea] > 0)} { 
                return $linea
            } 
        }

        return ""
    }

# this method implements a state-machine through 'read_line_proc'
# See tcl/newrwpage.tcl for an example

    proc setup_input_handler { ch read_line_proc } {
        fileevent $ch readable [list $read_line_proc $ch]
    }

    proc deregister_input_handler {ch} { fileevent $ch readable {} }

}

package provide rwterm 0.1
