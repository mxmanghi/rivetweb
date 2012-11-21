#
# -- test
#
# Can I stretch Rivetweb capabilities and make it suitable
# for dynamic website generation?
#
#

package require Itcl
package require ScriptBase

::itcl::class Test {
    inherit ScriptBase

    public method run {pageobj}
    public method doDump {language pageobj}
    public method doRun {language pageobj} 
}

# -- run
#
#
::itcl::body Test::run {pobj} {

    puts [html [pid] div]
    puts [html "running at [clock format [clock seconds]]" div b]
    puts [html "created at [clock format $setup_timestamp]" div h4]

}

# -- dump
#
#

::itcl::body Test::doDump {language pageobj} {
    $pageobj add_metadata title "Running method doDump"
}

# -- doRun
#
#

::itcl::body Test::doRun {language pageobj} {

    if {[catch {$pageobj add_metadata title "Running method doRun"} e]} {
        puts $e
    }

}

