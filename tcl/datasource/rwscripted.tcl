#
# -- rwscripted.tcl
#
# data source for scripts to be run within rivet. The
# datasource creates ::rwscripted pages to be stored in
# the core database
#
#

package require rwconf
package require rwlogger
package require rwsitemap
package require rwscripted

namespace eval ::Scripted {
    variable sitemap
    variable script_path tcl
    variable varsqs

    proc init {args} {
        variable sitemap
        variable script_path

        set sitemap     [::rwsitemap::create [namespace current]]
        set script_path [file normalize [file join $::rivetweb::site_base $script_path]]

# to speed up the development I just load the whole directory of scripts
# We need to pass to auto loading as soon as the mechanics has been set
# to work

        $::rivetweb::logger log notice "loading scripts from $script_path"        
        set tclfiles [glob -directory $script_path *.tcl]
        foreach script $tclfiles {
            $::rivetweb::logger log notice "sourcing $script"
            source $script
        }
    }

# -- script_ensemble

    proc script_ensemble {key} { 
        set script_ns [string totitle $key]
        return "[namespace current]::$script_ns" 
    }

# -- willHandle
#
#
    proc willHandle {arglist keyvar} {
        variable varsqs
        variable script_path
        upvar $keyvar key 

        set varsqs      [dict create {*}$arglist]
        set retcode     break
        set errorcode   rw_ok

        if {[dict exists $varsqs f]} {
            set key [dict get $varsqs f]
            set ensemble [script_ensemble $key]
            if {[namespace exists $ensemble]} {
                $::rivetweb::logger log info    \
                                    "mapping fun $key ($ensemble) for processing"
                return -code break -errorcode rw_ok
            } else {
                $::rivetweb::logger log err \
                                    "$ensemble namespace not existing"

            } 
        } 

        $::rivetweb::logger log info "[namespace current] not mapping request"
        return -code continue -errorcode rw_continue
    }

# -- fetchData 
#
#

    proc fetchData {key reassigned_key} {
        variable varsqs
        upvar $reassigned_key rkey

        set rkey $key

        set newpage [::rwpage::RWScripted ::#auto $key [script_ensemble $key]]
        $newpage put_metadata $varsqs
        [script_ensemble $key] setup $varsqs
        return $newpage
    }

    proc is_stale {key timereference } {
        return false
    }

    proc menu_list {page} {}

    namespace export *
    namespace ensemble create
}

package provide Scripted 1.0
