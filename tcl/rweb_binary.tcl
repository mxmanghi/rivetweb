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

        protected   variable binary_file
        public	    variable chunk_size   8192

        constructor {pagekey binfile} {RWPage::constructor $pagekey} { 
	        set binary_file $binfile
	    }

        public method binary_content { } { return true }
        public method print_binary { } 

    }

# --print_binary
#
# 

    ::itcl::body RWBinary::print_binary {} {
        ::rivet::apache_log_error notice "attempting to download $binary_file"
        if {[file exists $binary_file]} {
            
            set fname	    [file tail $binary_file]
            set file_size   [file size $binary_file]

            set proposed_mimetype [::fileutil::magic::mimetype $binary_file]
            #set mimetype    [exec xdg-mime query filetype $binary_file]

            if {$proposed_mimetype == "application/zip" && [regexp {^.+\.odp} $fname]} {

                # we assume it's an OpenDocument Presentation

                set mimetype "application/vnd.oasis.opendocument.presentation"

            } elseif {(($proposed_mimetype == "") || ($proposed_mimetype == "Microsoft Office Document")) && \
                         [regexp {^.+\.ppt$} $fname]} {

                set mimetype "application/vnd.ms-powerpoint"

            } elseif {$proposed_mimetype == ""} {
                set mimetype "application/octet-stream"
            } else {
                set mimetype $proposed_mimetype
            }

            ::rivet::apache_log_error info "Downloading file $binary_file ($mimetype)"
            set file_handle [open $binary_file r]
            fconfigure $file_handle -translation binary

            set stored_translation  [fconfigure stdout -translation]
            set stored_encoding     [fconfigure stdout -encoding]
            fconfigure stdout       -translation binary

            ::rivet::headers type                    $mimetype
            ::rivet::headers add Content-Disposition "attachment; filename=\"$fname\""
            ::rivet::headers add Content-Length	     $file_size

            set nrecs	    0
            set sent_data   0
            while {1} {

                set chunk	    [read $file_handle $chunk_size]
                incr sent_data	[string length $chunk]

                if {[eof $file_handle]} {
                    close $file_handle
                    puts -nonewline $chunk
                    flush stdout
                    apache_log_error debug "$fname downloaded: $sent_data bytes sent in $nrecs chunks"
                    break
                } 
                puts -nonewline $chunk
                incr nrecs

            }
            
            fconfigure stdout   -translation $stored_translation -encoding $stored_encoding
        } else {
            ::rivet::apache_log_error err "not existing file $binary_file in class RWBinary"
        }
    }
}

package provide rwbinary 0.1
