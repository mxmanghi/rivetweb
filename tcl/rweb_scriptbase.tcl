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
    protected method error_descriptor {code args}
    public method setup {argsdict} { set stored_vars $argsdict }
    public method prepare {} { return true } 
    public method template {pageobj rvtname}
    public method run {pageobj}
    public method menu_list {page} { return {} }
}

# -- template
#
#
::itcl::body ScriptBase::template {pageobj rvtname} {
    parse [file join $::rivetweb::site_base rvt "${rvtname}.rvt"]
}

# -- run
#
#
::itcl::body ScriptBase::run {pageobj} {
    puts "<b>[namespace current]</b>"
}

# -- error_descriptor
#
#
::itcl::body ScriptBase::error_descriptor {code args} {
    set d [dict create -errorcode $code]

    foreach {par val} $args { dict set d $par $val }

    return $d
}

package provide ScriptBase 0.1
