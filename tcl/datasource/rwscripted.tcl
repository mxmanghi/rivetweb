#
# -- rwscripted.tcl
#
# data source for scripts to be run within rivet. The
# datasource creates ::rwscripted pages to be stored in
# the core database
#
#
package require Itcl
package require Datasource
package require rwconf
package require rwlogger
package require rwsitemap
package require rwscripted
package require rwmenu
package require ScriptBase


namespace eval ::rwdatas {

    ::itcl::class Scripted {
        inherit Datasource

        private variable sitemap
        private variable script_path tcl
        private variable varsqs
        private variable scriptsdb
        
        public method init {args}
        public method willHandle {arglist keyvar}
        public method fetchData {key reassigned_key}
        public method is_stale {key timereference } { return false }
        public method menu_list {page} 
        public method rewrite_url {rwcode urlscript urlargs rewritten_base}
    }

    ::itcl::body Scripted::init {args} {

        set sitemap     [::rwsitemap::create [namespace current]]
        set script_path [file normalize [file join $::rivetweb::site_base $script_path]]
        set scriptsdb   [dict create]

# to speed up the development I just load the whole directory of scripts
# We need to pass to auto loading as soon as the mechanics has been set
# to work

        $::rivetweb::logger log notice "loading scripts from $script_path"        
        set tclfiles [glob -nocomplain -directory $script_path *.tcl]
        foreach script $tclfiles {
            $::rivetweb::logger log notice "sourcing $script"
            catch { array unset rwdescriptor }
            source $script

            if {[info exists rwdescriptor(classname)]} { 
                set cmdname $rwdescriptor(classname)
            } else {
                set cmdname     [file rootname [file tail $script]]
            }
            set classname "[namespace current]::[string totitle $cmdname]"
                
            dict set scriptsdb $cmdname class   $classname 
            dict set scriptsdb $cmdname object  [$classname ::#auto]
        }
    }

# -- willHandle
#
#
    ::itcl::body Scripted::willHandle {arglist keyvar} {
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

    ::itcl::body Scripted::fetchData {key reassigned_key} {
        upvar $reassigned_key rkey

        set rkey $key
        set scriptobj [dict get $scriptsdb $rkey object]
        $scriptobj setup $varsqs

        set newpage [::rwpage::RWScripted ::#auto $key $scriptobj]
        $newpage put_metadata $varsqs

        return $newpage
    }

# -- menu_list
#
#

    ::itcl::body Scripted::menu_list {page} { 

        set menudb [dict create]
        #puts stderr "<div style=\"background: yellow;\">menudb created ($menudb)</div>"

        foreach script [dict keys $scriptsdb] {
            set scriptobj [dict get $scriptsdb $script object]
            set menul [$scriptobj menu_list $page]

    #
    # the list returned by 'menu_list' should be structured like
    #
    # group1 menu_list1 group2 menu_list2
    #

            foreach {menu_group menulist} $menul {
                dict lappend menudb $menu_group {*}$menulist
            }
        }

        #puts "<div style=\"background: yellow;\">rwscripted: $menudb</div>"

        return $menudb
    }

# -- rewrite_url
#
#

    ::itcl::body Scripted::rewrite_url {rwcode urlbase urlargs rewritten_base} {
        upvar $rewritten_base rwbase
        upvar $urlargs        urlencoded

        set d [dict create {*}$urlencoded]

        ::rivet::apache_log_error notice " --> $d"
        if {[dict exists $d f]} {
            set rwbase "/[dict get $d f]/"
            dict unset d f
            set urlencoded $d

            ::rivet::apache_log_error notice "URL $rwbase ($urlencoded) rewritten"

            return -code break -errorcode rw_break
        }

        return -code continue -errorcode rw_continue
    }
}

package provide Scripted 2.0
