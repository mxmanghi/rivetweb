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
package require rwmenu
package require ScriptBase

namespace eval ::Scripted {
    variable sitemap
    variable script_path tcl
    variable varsqs
    variable scriptsdb

# -- init
#
#
    proc init {args} {
        variable sitemap
        variable script_path
	    variable scriptsdb

        set sitemap     [::rwsitemap::create [namespace current]]
        set script_path [file normalize [file join $::rivetweb::site_base $script_path]]
	    set scriptsdb	[dict create]

# to speed up the development I just load the whole directory of scripts
# We need to pass to auto loading as soon as the mechanics has been set
# to work

        $::rivetweb::logger log notice "loading scripts from $script_path"        
        set tclfiles [glob -nocomplain -directory $script_path *.tcl]
        foreach script $tclfiles {
            $::rivetweb::logger log notice "sourcing $script"
            source $script

	        set cmdname	    [file rootname [file tail $script]]
	        set classname   "[namespace current]::[string totitle $cmdname]"

	        dict set scriptsdb $cmdname class	$classname 
	        dict set scriptsdb $cmdname object	[$classname ::#auto]
        }
    }

# -- willHandle
#
#
    proc willHandle {arglist keyvar} {
        variable varsqs
        variable script_path
	    variable scriptsdb

        upvar $keyvar key 

        set varsqs      [dict create {*}$arglist]
        set retcode     break
        set errorcode   rw_ok

        if {[dict exists $varsqs f]} {
            set key [dict get $varsqs f]
            if {[dict exists $scriptsdb $key]} {

                $::rivetweb::logger log info    \
                                    "mapping fun $key ([dict get $scriptsdb $key]) for processing"
                return -code break -errorcode rw_ok

            } else {
                $::rivetweb::logger log err \
                                    "'$key' function not existing"

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
	    variable scriptsdb

        upvar $reassigned_key rkey

        set rkey $key
	    set scriptobj [dict get $scriptsdb $rkey object]
        $scriptobj setup $varsqs

        set newpage [::rwpage::RWScripted ::#auto $key $scriptobj]
        $newpage put_metadata $varsqs

        return $newpage
    }

    proc is_stale {key timereference } { return false }

    proc menu_list {page} { 
        variable scriptsdb

        set menudb [dict create]
        foreach script [dict keys $scriptsdb] {
            set scriptobj [dict get $scriptsdb $script object]
            set menul [$scriptobj menu_list $page]
            if {[llength $menul]} { dict set menudb {*}$menul }
        }

        return $menudb
    }

    namespace export *
    namespace ensemble create
}

package provide Scripted 1.0
