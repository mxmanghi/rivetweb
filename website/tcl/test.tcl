#
# -- test
#
# Can I stretch Rivetweb capabilities and make it suitable
# for dynamic website generation?
#
#

namespace eval Test {
    variable timestamp

    proc prepare {args} {
        variable timestamp

        set timestamp [clock format [clock seconds]]
    }

    namespace export *
    namespace ensemble create
} 
