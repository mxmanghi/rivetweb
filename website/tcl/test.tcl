#
# -- test
#
# Can I stretch Rivetweb capabilities and make it suitable
# for dynamic website generation?
#
#

namespace eval Test {
    variable setup_timestamp
    variable stored_vars

# -- setup
#
# this procedure is called when the scripting method is first setup by
# the framework

    proc setup {argsdict} {
        variable setup_timestamp
        variable stored_vars

        set stored_vars $argsdict
        set setup_timestamp [clock seconds]
    }

# -- prepare
#

    proc prepare {} {
        variable stored_vars

        return true       
    }


# -- run
#
#
    proc run {} {
        variable setup_timestamp
        puts [html [pid] div]
        puts [html "running at [clock format [clock seconds]]" div b]
        puts [html "created at [clock format $setup_timestamp]" div h4]
    }

    namespace export *
    namespace ensemble create
} 
