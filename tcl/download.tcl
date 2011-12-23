# -- download.tcl
#
# Procedure for downloading (binary) files. It requires a fname variable with the name of
# a graphic file to look for
# 
# $Id: download.tcl 2104 2011-12-18 00:24:45Z massimo.manghi $
#
#   apache_log_error notice "[info script] -> [pwd]"

    package require fileutil::magic::mimetype

    if {[var exists fname]} {

        cd $::rivetweb::site_base

        set file_path [file join [::rivetweb::makePictsPath [var get fname] $::rivetweb::template_key]]
        apache_log_error err "got download request for $file_path"

        if {[file exists $file_path]} {

        # The file exists so we go ahead reading its size and determining its mime type

            set file_size [file size $file_path]
            set fname     [var get fname]
            set mimetype  [::fileutil::magic::mimetype $file_path]

        # We open the file and prepare the HTTP headers

            set file_handle [open $file_path r]
            fconfigure $file_handle -translation binary
            fconfigure stdout -translation binary
            headers type                    $mimetype
            headers add Content-Disposition "attachment; filename=\"$fname\""
            headers add Content-Length		$file_size

        # we send it in one or more chunks

            set nrecs 0
            set sent_data  0
            while {1} {

                set file_data  [read $file_handle $::rivetweb::download_chunksize]
                incr sent_data [string length $file_data]

                if {[eof $file_handle]} {
                    close $file_handle
                    puts -nonewline $file_data
                    flush stdout
                    break
                } 
                incr nrecs
                puts -nonewline $file_data

                apache_log_error debug "rec $nrecs"
            }

            apache_log_error info "download $file_path, transimitted $sent_data bytes in $nrecs chunk(s)"
        }
        set ::rivetweb::download_fname ""
    }
