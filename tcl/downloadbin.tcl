#
# -- downloadbin.tcl
#
#

package require rwbinary

namespace eval ::rwpage {

    ::itcl::class DownloadBin  {
        inherit RWBinary

        private variable file_name
        private variable data_sent
        public	variable chunk_size   [expr 8*8192]

        constructor {key filen} {RWBinary::constructor $key} {
            set file_name $filen 
        }

        public method binary_data {language}
        public method content_disposition {} { return "" }
        public method content_length {}
        public method filename {} { return $file_name }
    }

    ::itcl::body DownloadBin::content_disposition {} {
        return "attachment; filename=\"[file tail $file_name]\""
    }

    ::itcl::body DownloadBin::content_length {} {
        return [file size $file_name]
    }

    ::itcl::body DownloadBin::binary_data {language} {
        ::rivet::apache_log_error notice "attempting to download $file_name"
        set file_handle [open $file_name r]
        fconfigure $file_handle -translation binary

        #set mylog [open "/tmp/bin-[pid]-[incr count].log" w]

        set nrecs	    0
        set data_sent   0
        set loop        1
        while {$loop} {
            set chunk	    [read $file_handle $chunk_size]
            incr data_sent	[string length $chunk]

            if {[eof $file_handle]} {
                close $file_handle
                puts -nonewline $chunk
                flush stdout

                ::rivet::apache_log_error debug \
                    "[file tail $file_name] downloaded: $data_sent bytes sent in $nrecs chunks"

                set loop 0

            } else {

                puts -nonewline $chunk
                incr nrecs

            } 
        }

        return $data_sent
    }
}

package provide downloadbin 1.0
