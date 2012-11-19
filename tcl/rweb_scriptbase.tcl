#
# -- rweb_scriptbase.tcl
#
#

package require Itcl

::itcl::class ScriptBase {
    
    protected variable setup_timestamp
    protected variable stored_vars

    constructor {} {
	set stored_vars		{}
	set setup_timestamp	[clock seconds]
    }
    
    public method setup {argsdict} { set stored_vars $argsdict }
    public method prepare {} { return true } 
    public method template {rvtname}
    public method run {}
}

# -- template
#
#

::itcl::body ScriptBase::template {rvtname} {

    parse [file join $::rivetweb::site_base rvt "${rvtname}.rvt"]

}

# -- run
#
#
::itcl::body ScriptBase::run {} {
    puts "<b>[namespace current]</b>"
}

package provide ScriptBase 0.1
