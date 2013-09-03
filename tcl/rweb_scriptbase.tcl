#
# -- rweb_scriptbase.tcl
#
#

package require Itcl
package require rwmenu

::itcl::class ScriptBase {
    
    protected variable setup_timestamp

    constructor {} {
        set setup_timestamp	[clock seconds]
    }
    public method setup {argsdict} { set stored_vars $argsdict }
    public method init {language pageobj} { }
    public method handler {options}  { }
    public method prepare {} { return true } 
    public method template {pageobj rvtname}
    public method run {pageobj}
    public method menu_list {page} { return {} }
}

# -- template
#
# this methods is in charge for peeking the template file and 
# parse it.

::itcl::body ScriptBase::template {pageobj rvtname} {
    parse [file join $::rivetweb::site_base rvt "${rvtname}.rvt"]
}

# -- run
#
#

::itcl::body ScriptBase::run {pageobj} {
    puts "<b>[namespace current]</b>"
}

package provide ScriptBase 0.1
