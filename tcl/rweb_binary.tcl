#
# -- rweb_binary
#
# page model for a binary transfer function
#
#

package require Itcl
package require rwpage
package require fileutil::magic::mimetype

namespace eval ::rwpage {

    ::itcl::class RWBinary {
        inherit RWPage

        private variable binary_file
        public	variable chunk_size   8192

        constructor {pagekey binfile} {RWPage::constructor $pagekey} { 
	    set binary_file $binfile
	}

        public method binary_content { } { return true }
        public method print_binary {} 
    }

# --print_binary
#
# 

    ::itcl::body RWBinary::print_binary {} {

        if {[file exists $binary_file]} {
            
            set fname	    [file tail $binary_file]
            set file_size   [file size $binary_file]
            set mimetype    [::fileutil::magic::mimetype $binary_file]
            #set mimetype    [exec xdg-mime query filetype $binary_file]

            if {($mimetype == "") || ($mimetype == "Microsoft Office Document")} {
                if {[regexp {^.+\.ppt$} $fname]} {
                    set mimetype "application/vnd.ms-powerpoint"
                } else {
                    set mimetype "application/octet-stream"
                }
            }

            apache_log_error info "Downloading file $binary_file ($mimetype)"
            set file_handle [open $binary_file r]
            fconfigure $file_handle -translation binary
            fconfigure stdout       -translation binary
            headers type                    $mimetype
            headers add Content-Disposition "attachment; filename=\"$fname\""
            headers add Content-Length	    $file_size

            set nrecs	    0
            set sent_data   0
            while {1} {

                set chunk	[read $file_handle $chunk_size]
                incr sent_data	[string length $chunk]

                if {[eof $file_handle]} {
                    close $file_handle
                    puts -nonewline $chunk
                    flush stdout
                    break
                } 
                incr nrecs
                puts -nonewline $chunk

                apache_log_error debug "file downloaded in $nrecs chunks"
            }
        }
    }

}

package provide rwbinary 0.1
