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

    public method run {}
    public method dump {}

}

# -- run
#
#
::itcl::body Test::run {} {

    puts [html [pid] div]
    puts [html "running at [clock format [clock seconds]]" div b]
    puts [html "created at [clock format $setup_timestamp]" div h4]

}

# -- dump
#
#

::itcl::body Test::dump {} {
    puts "pwd: [pwd]"
}

