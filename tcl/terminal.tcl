# -- terminal.tcl
#
# terminal io for configuration procedures 
#

namespace eval ::rwterm {

    proc prompt {termch prompt_line} {
        puts -nonewline $termch $prompt_line
        flush $termch
    }

    proc parse_line {linea} {
        if {[file exists $linea] && [file isdirectory $linea]} {
            puts stderr "$linea existing"
        } else {

            if {[catch {[file mkdir $linea]} e]} {

                puts "Error creating $linea:\n$e"

            } else {

                create_website $linea

            }
        }
    }

    proc get_line {ch prompt_line input_line} {
        upvar $input_line line    

        prompt stdout $prompt_line
        return [gets stdin line]

    }

    proc read_input_line {ch prompt_line} {

        while {![eof $ch] && ([get_line stdin $prompt_line linea] <= 0)} {
     
        } 

        return $linea
    }

    proc termio_setup {} {
        fileevent stdin readable [list leggi_linea stdin]
    }

}

package provide rwterm 0.1
