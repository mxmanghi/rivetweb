#
# $Id: error_rvt.tcl 1060 2011-05-01 08:26:55Z massimo.manghi $
#
#

load_env

if {[info exists env(REQUEST_URI)]} {
    set requested_file [lindex [file split $env(REQUEST_URI)] end]
    puts stderr "requesting file ${requested_file}"
    
    if {[string match $requested_file index.html]} {
        set requested_page main
        set ::rivetweb::static_links true
        parse index.rvt
    } elseif {[regexp {(.+)\.html$} $requested_file m requested_page]} {
#    	headers redirect http://localhost/~manghi/rivet/index.rvt?show=${requested_page}
        puts stderr "matched $requested_file: going to require reference '$requested_page'"
        set ::rivetweb::static_links true
        parse index.rvt
    } else {
    	parse error.rvt
    }
} else {
    parse error.rvt
}



