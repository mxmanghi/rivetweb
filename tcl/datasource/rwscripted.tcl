#
# -- rwscripted.tcl
#
#
#
#

package require rwconf
package require rwlogger
package require rwsitemap
package require rwpmodel

namespace eval ::RwScripted {
    variable sitemap
    variable script_path tcl


    proc init {args} {
        variable sitemap
        variable script_path
        variable ensemble

        set sitemap         [::rwsitemap::create ::RwScripted]
        set script_path     [file normalize [file join $:rivetweb::site_base $script_path]

# to speed up the development I just load the whole directory of scripts

        set tclfiles [glob -directory $script_path *.tcl]
        foreach script $tclfiles {
            $::rivetweb::logger log info "sourcing $script"
            source $script
        }
    }


    proc willHandle {arglist keyvar} {
        variable script_path
        variable ensemble
        upvar $keyvar key 

        set retcode break
        set errorcode rw_ok

        if {[dict exists $arglist fun]} {
            set key [dict get $arglist fun]
            set script_ns [string totitle $key]
            set ensemble [namespace current]::$key
            if {[namespace exists $ensemble]} {
                $::rivetweb::logger log info "mapping fun $key ($script_ns) for processing"
                return -code break -errorcode rw_ok
            } 
        } 

        $::rivetweb::logger log info "::XMLScripted not mapping $key"
        return -code continue -errorcode rw_continue
    }

# -- fetchData 

    proc fetchData {key reassigned_key} {
        upvar $reassigned_key rkey

        set rkey $key
        $ensemble prepare {*}[var all]
    }

    proc is_stale {key timereference } {
        return true
    }
    namespace export *
    namespace ensemble create
}
